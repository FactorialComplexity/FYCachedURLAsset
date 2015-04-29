//
//  FYContentLoader.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/23/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

// Model
#import "FYContentProvider.h"
#import "FYContentProvider+Classes.h"
#import "FYCachedURLAsset.h"
#import "FYDownloadSession.h"

// Frameworks
@import SystemConfiguration;

#pragma mark - FYContentProvider

#define DEBUG_CONTENT_PROVIDER 1

#if DEBUG_CONTENT_PROVIDER
#define NSLog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
#define NSLog(format, ...)
#endif

static NSTimeInterval const kMaximumWaitingTimeTreshold = 5.0f;

typedef void (^FYReachabilityCallback) (BOOL isConnectedToTheInternet);

/**
 *  Known issues:
 *	1. All io tasks are performed on main queue.
 *	2. If download failed -> this code doesn't resume downloading if internet connection did appear again.
 *	3. We always tell to resource loader that we will process it's request.
 *	4. Sometimes resource loader doesn't want to ask for data.
 *	5. Some media doesn't load 'duration' for asset.
 *	6. Sometimes videos are played without sound.
 */

/**
 *  Class that gives media data for content requesters.
 */
@interface FYContentProvider ()
<
AVAssetResourceLoaderDelegate
>
@end

@implementation FYContentProvider {
	// Reachability related.
	SCNetworkReachabilityRef _reachability;
	SCNetworkReachabilityFlags _latestReachabilityFlags;
	// Callbacks that need to know current network status.
	NSMutableArray *_networkReachableWaiters;
	
	NSMutableArray *_contentRequesters;
}

#pragma mark - Singleton

+ (instancetype)shared {
	static id manager = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		manager = [self new];
	});
	
	return manager;
}

#pragma mark - Lifecycle

- (instancetype)init {
	if (self = [super init]) {
		_contentRequesters = [NSMutableArray new];
		
		_reachability = SCNetworkReachabilityCreateWithName(NULL, "www.google.com");
		_networkReachableWaiters = [NSMutableArray new];
		
		SCNetworkReachabilityContext ctx = {0};
		ctx.version = 0;
		ctx.info = (__bridge void *)(self);
		
		SCNetworkReachabilitySetCallback(_reachability, NetworkReachabilityCallBack, &ctx);
		SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetMain(), (CFStringRef)NSRunLoopCommonModes);
	}
	return self;
}

- (void)dealloc {
	// Thus it never happens, but this is good coding style to release allocated stuff.
	SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), NULL);
	CFRelease(_reachability);
}

#pragma mark - Public

- (void)startResourceLoadingFromURL:(NSURL *)url toCachedFilePath:(NSString *)cachedFilePath
			withResourceLoader:(AVAssetResourceLoader *)loader {
	[loader setDelegate:self queue:dispatch_get_main_queue()];
	
	// Check if we're already loading something from given URL.
	BOOL alreadyLoading = NO;
	
	for (FYContentRequester *requester in _contentRequesters) {
		// Allow multiple requesters ONLY if we're streaming from cache, because it's not stable to do that without fully loaded resource.
		if ([requester.resourceURL isEqual:url] &&
			[requester.cacheFilenamePath isEqualToString:cachedFilePath] &&
			requester.isStreamingFromCache) {
			
			alreadyLoading = YES;
			
			requester.totalRequestersCount++;
			
			FYResourceLoader *resourceLoader = [[FYResourceLoader alloc] initWithLoader:loader];
			[requester.resourceLoaders addObject:resourceLoader];
			
			break;
		}
	}
	
	NSLog(@"[ContentProvider]: Registering URL: %@->%@. Already loading: %@",
		  [url lastPathComponent],
		  cachedFilePath,
		  alreadyLoading ? @"YES" : @"NO");
	
	if (!alreadyLoading) {
		// We're not loading from given URL yet.
		FYContentRequester *requester = [[FYContentRequester alloc] initWithURL:url cacheFilePath:cachedFilePath
											resourceLoader:loader];
		
		// Setup callbacks for session.
		[self setupCallbacksForRequester:requester];
		
		[_contentRequesters addObject:requester];
		
		[self determineIsNetworkReachableWithCallback:^(BOOL isConnectedToTheInternet) {
			// We determined is we're currently connected to the internet.
			// What should we do next?
			// 1. If we haven't got cached file - try to download it from server. If we're not connected to the internet we can't do anything.
			// 2. If we have got cached file - check is it up-to date on server. If we don't have connection -> play from cache.
			// 3. If cached file is up-to date -> simply play it.
			NSString *metaFilePath = [cachedFilePath stringByAppendingString:[self metadataFileSuffix]];
			NSString *tempFilePath = [cachedFilePath stringByAppendingString:[self temporaryFileSuffix]];
			
			BOOL cachedFileExist = [[NSFileManager defaultManager] fileExistsAtPath:cachedFilePath];
			BOOL metaFileExist = [[NSFileManager defaultManager] fileExistsAtPath:metaFilePath];
			BOOL tempCachedFileExist = [[NSFileManager defaultManager] fileExistsAtPath:tempFilePath];
			
			// Stream from cache method is async, so some bad things can happen.
			// But we don't care, coz we'll store needed data right now.
			FYCachedFileMeta *metadataFile = [NSKeyedUnarchiver unarchiveObjectWithFile:metaFilePath];
			NSData *cachedData = [NSData dataWithContentsOfFile:cachedFileExist ? cachedFilePath : tempFilePath];
			
			void (^streamFromCacheBlock) () = ^{
				requester.metadataFile = metadataFile;
				requester.localData = cachedData;
				[requester.contiguousData appendData:cachedData];
				
				requester.isStreamingFromCache = cachedFileExist;
				
				if (!cachedFileExist) {
					NSLog(@"[ContentProvider]: Cached file isn't fully downloaded!");
					if (isConnectedToTheInternet) {
						// Note: isConnected may be not correct, but NSURLConnection will simply fail.
						[requester.session startLoadingFromOffset:requester.localData.length entityTag:requester.metadataFile.etag];
					}
				}
				
				// This invocation is may be async, so AVFoundation may ask us for data.
				[self processPendingRequestsForRequester:requester];
			};

			if (metaFileExist && (cachedFileExist || tempCachedFileExist)) {
				NSLog(@"[ContentProvider]: Got cached file!");

				if (isConnectedToTheInternet) {
					NSLog(@"[ContentProvider]: Will check is cached file is up-to date.");
					// Check is cached file is up-to date.
					[requester.session fetchEntityTagForResourceWithSuccess:^(NSString *etag) {
						if ([etag isEqualToString:metadataFile.etag]) {
							// Everything is ok, simply play file from cache.
							NSLog(@"[ContentProvider]: Cached file is up-to date!");
							streamFromCacheBlock();
						} else {
							// File changed on server, redownload it.
							NSLog(@"[ContentProvider]: Cached file is out of date! Will download new!");
							[[NSFileManager defaultManager] removeItemAtPath:metaFilePath error:nil];
							[[NSFileManager defaultManager] removeItemAtPath:cachedFilePath error:nil];
							[[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
							
							[requester.session startLoadingFromOffset:0 entityTag:nil];
						}
					} failure:^(NSError *error, NSInteger statusCode) {
						NSLog(@"[ContentProvider]: Failed to check is cached file is up-to date with error: %@", error);
						// Stream file that we currently have.
						streamFromCacheBlock();
					}];
				} else {
					NSLog(@"[ContentProvider]: Hasn't got internet connection, can't change is resource up-to date. Will stream from cached file.");
					streamFromCacheBlock();
				}
			} else {
				// Simply start downloading from beggining.
				NSLog(@"[ContentProvider]: Hasn't got cached files. Will download from scratch!");
				if (isConnectedToTheInternet) {
					[requester.session startLoadingFromOffset:0 entityTag:nil];
				} else {
					NSLog(@"[Warning]: Isn't connected to the internet. Can't stream anything.");
				}
			}
		}];
	}
}

- (void)stopResourceLoadingFromURL:(NSURL *)url cachedFilePath:(NSString *)cachedFilePath {
	FYContentRequester *requester = [self contentRequesterForURL:url cachedFilePath:cachedFilePath];
	
	requester.totalRequestersCount--;

	if (requester.totalRequestersCount == 0) {
		// TODO: Maybe save currently gathered data into ~part file?
		
		// Perform cleanup.
		for (FYResourceLoader *loader in requester.resourceLoaders) {
			// TODO: Fill with normal error.
			[loader.latestRequest finishLoadingWithError:[NSError errorWithDomain:NSCocoaErrorDomain
																			 code:0
																		 userInfo:nil]];
			
			[loader.loader setDelegate:nil queue:dispatch_get_main_queue()];
			loader.latestRequest = nil;
			loader.loader = nil;
		}
		
		[requester.resourceLoaders removeAllObjects];
		
		requester.session.responseBlock = nil;
		requester.session.chunkDownloadBlock = nil;
		requester.session.successBlock = nil;
		requester.session.failureBlock = nil;
		requester.session.resourceChangedBlock = nil;
		
		[requester.session cancelLoading];
		
		[_contentRequesters removeObject:requester];
	}
}

#pragma mark - Private

- (NSURL *)modifySongURL:(NSURL *)url withCustomScheme:(NSString *)scheme {
	NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
	components.scheme = scheme;
 
	return [components URL];
}

- (void)setupCallbacksForRequester:(FYContentRequester *)requester {
	__typeof(requester) __weak weakRequester = requester;

	requester.session.responseBlock = ^(NSHTTPURLResponse *response) {
		NSLog(@"Response: %@", response);
		FYCachedFileMeta *fileMeta = [[FYCachedFileMeta alloc] initWithResponse:response fromSession:weakRequester.session];
		
		weakRequester.metadataFile = fileMeta;
		
		// Save response in metadata file.
		NSString *metadataFilePath = [weakRequester.cacheFilenamePath stringByAppendingString:[self metadataFileSuffix]];
		NSData *metadataBytes = [NSKeyedArchiver archivedDataWithRootObject:fileMeta];
		[metadataBytes writeToFile:metadataFilePath atomically:NO];
		
		[self processPendingRequestsForRequester:weakRequester];
	};
	
// TODO: Refactor that. Create download storage.
	requester.session.chunkDownloadBlock = ^(NSData *chunk) {
		// Offset in resource
		NSInteger contiguousOffset = weakRequester.session.offset + weakRequester.session.downloadedData.length - chunk.length;
		
//		NSLog(@"Contuguos offset: %d. Contiguous data length: %d", (int32_t)contiguousOffset, (int32_t)weakRequester.contiguousData.length);
		
		if (contiguousOffset <= weakRequester.contiguousData.length &&
			(contiguousOffset + chunk.length) >= weakRequester.contiguousData.length) {
			NSRange bytesRangeToAppend = (NSRange) {
				weakRequester.contiguousData.length - contiguousOffset,
				contiguousOffset + chunk.length - weakRequester.contiguousData.length
			};
			
			[weakRequester.contiguousData appendData:[chunk subdataWithRange:bytesRangeToAppend]];
		}
		
		[self processPendingRequestsForRequester:weakRequester];
		
//		 Testing.
		!self.progressBlock ? : self.progressBlock(weakRequester.session.offset,
												   weakRequester.localData.length,
												   weakRequester.session.downloadedData.length,
												   weakRequester.metadataFile.contentLength);
	};
	
// TODO: Refactor (create download storage)
	requester.session.successBlock = ^{
		NSLog(@"Will save ? %@", (weakRequester.streamingState == kStreamingStateStreaming ? @"YES" : @"NO"));
		
		if (weakRequester.contiguousData.length == weakRequester.metadataFile.contentLength) {
			[weakRequester.contiguousData writeToFile:weakRequester.cacheFilenamePath atomically:NO];
			
			// Cleanup any temp files that may exist in case of resuming download.
			NSString *tempFilePath = [weakRequester.cacheFilenamePath stringByAppendingString:[self temporaryFileSuffix]];
			[[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
		} else if (weakRequester.streamingState == kStreamingStateStreaming &&
				   (weakRequester.localData.length > 0 ||
					weakRequester.session.downloadedData.length > 0)) {
					   
					   NSMutableData *fullMediaData = [NSMutableData new];
					   
					   [fullMediaData appendData:weakRequester.localData];
					   [fullMediaData appendData:weakRequester.session.downloadedData];
					   [fullMediaData writeToFile:weakRequester.cacheFilenamePath atomically:NO];
					   
					   // Cleanup any temp files that may exist in case of resuming download.
					   NSString *tempFilePath = [weakRequester.cacheFilenamePath stringByAppendingString:[self temporaryFileSuffix]];
					   [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];

		}
		
		[self processPendingRequestsForRequester:weakRequester];
	};
	
	requester.session.failureBlock = ^(NSError *error, NSInteger statusCode) {
		NSLog(@"Failure: %@. Status code: %d", error, (int32_t)statusCode);
		
		if (statusCode == 404) {
			[[NSNotificationCenter defaultCenter] postNotificationName:FYResourceForURLDoesntExistNotificationName
																object:weakRequester.resourceURL];
		}
		
		// Save all gathered data to ~part file.
		if (weakRequester.streamingState == kStreamingStateStreaming &&
			(weakRequester.localData.length > 0 ||
			 weakRequester.session.downloadedData.length > 0)) {
				
				NSString *partFilePath = [weakRequester.cacheFilenamePath stringByAppendingString:@"~part"];
				NSMutableData *fullMediaData = [NSMutableData new];
				
				[fullMediaData appendData:weakRequester.localData];
				[fullMediaData appendData:weakRequester.session.downloadedData];
				
				[fullMediaData writeToFile:partFilePath atomically:NO];
		}
		
		for (FYResourceLoader *loader in weakRequester.resourceLoaders) {
			if (loader.latestRequest) {
				// Give last chance to satisfy latest request.
				BOOL didSatisfy = [self tryToSatisfyRequest:loader.latestRequest forRequester:weakRequester];
				
				if (didSatisfy) {
					[loader.latestRequest finishLoading];
				} else {
					// TODO: Error
					[loader.latestRequest finishLoadingWithError:nil];
				}
				
				loader.latestRequest = nil;
			}
		}
	};
	
	requester.session.resourceChangedBlock = ^{
		// Resource changed. We need to invalidate.
		NSLog(@"[ContentProvider]: Resource changed! Will invalidate!");
		
		// Remove all files
		NSString *cachedFilePath = weakRequester.cacheFilenamePath;
		NSString *metaFilePath = [cachedFilePath stringByAppendingString:[self metadataFileSuffix]];
		NSString *tempFilePath = [cachedFilePath stringByAppendingString:[self temporaryFileSuffix]];

		[[NSFileManager defaultManager] removeItemAtPath:metaFilePath error:nil];
		[[NSFileManager defaultManager] removeItemAtPath:cachedFilePath error:nil];
		[[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];

		// Cleanup cached data.
		weakRequester.metadataFile = nil;
		weakRequester.localData = nil;
		
		// Remove resouce loaders.
		for (FYResourceLoader *loader in weakRequester.resourceLoaders) {
			// TODO: Fill with normal error.
			[loader.latestRequest finishLoadingWithError:[NSError errorWithDomain:NSCocoaErrorDomain
																			 code:0
																		 userInfo:nil]];
			
			[loader.loader setDelegate:nil queue:dispatch_get_main_queue()];
			loader.latestRequest = nil;
			loader.loader = nil;
		}
		
		[weakRequester.resourceLoaders removeAllObjects];
		
		// Notify about failure.
		[[NSNotificationCenter defaultCenter] postNotificationName:FYResourceForURLChangedNotificationName
			object:weakRequester.resourceURL];
	};
}

- (void)processPendingRequestsForRequester:(FYContentRequester *)requester {
	for (FYResourceLoader *loader in requester.resourceLoaders) {
		if (loader.latestRequest) {
			BOOL didSatisfy = [self tryToSatisfyRequest:loader.latestRequest forRequester:requester];
			
			if (didSatisfy) {
				[loader.latestRequest finishLoading];
				loader.latestRequest = nil;
			}
		}
	}
}

- (BOOL)tryToSatisfyRequest:(AVAssetResourceLoadingRequest *)request forRequester:(FYContentRequester *)requester {
	if (request.isCancelled) {
		// If request is cancelled - it somehow satisfied.
		return YES;
	}
	
	// Info / data requests are optional, we've handled them if they are not present.
	BOOL didRespondToInformationRequest = request.contentInformationRequest ? NO : YES;
	BOOL didRespondToDataRequest = request.dataRequest ? NO : YES;
	
	if (request.contentInformationRequest) {
		if (requester.metadataFile) {
			request.contentInformationRequest.contentType = requester.metadataFile.mimeType;
			request.contentInformationRequest.contentLength = requester.metadataFile.contentLength;
			request.contentInformationRequest.byteRangeAccessSupported = YES;
			
			didRespondToInformationRequest = YES;
		}
	}
	
	if (request.dataRequest) {
		AVAssetResourceLoadingDataRequest *dataRequest = request.dataRequest;
		
		if (requester.streamingState == kStreamingStateStreaming) {
			NSInteger totalBytesGot = requester.localData.length + requester.session.downloadedData.length;

			if (dataRequest.currentOffset < totalBytesGot) {
				NSInteger bytesGot = totalBytesGot - dataRequest.currentOffset;
				NSInteger bytesToGive = MIN(bytesGot, dataRequest.requestedOffset + dataRequest.requestedLength - dataRequest.currentOffset);
				
				NSRange chunkRange = (NSRange) {
					dataRequest.currentOffset,
					bytesToGive
				};
				
				NSMutableData *availableData = [NSMutableData new];
				[availableData appendData:requester.localData];
				[availableData appendData:requester.session.downloadedData];
				
				[dataRequest respondWithData:[availableData subdataWithRange:chunkRange]];
				
				didRespondToDataRequest = dataRequest.currentOffset >= (dataRequest.requestedOffset + dataRequest.requestedLength);
			}
		} else if (requester.streamingState == kStreamingStateOnDemand) {
			NSInteger totalBytesGot = requester.session.offset + requester.session.downloadedData.length;
			
			if (dataRequest.currentOffset >= requester.session.offset &&
				dataRequest.currentOffset < totalBytesGot) {
				
				NSInteger bytesGot = totalBytesGot - dataRequest.currentOffset;
				NSInteger bytesToGive = MIN(bytesGot, dataRequest.requestedOffset + dataRequest.requestedLength - dataRequest.currentOffset);
				
				NSRange chunkRange = (NSRange) {
					dataRequest.currentOffset - requester.session.offset,
					bytesToGive
				};
				
				[dataRequest respondWithData:[requester.session.downloadedData subdataWithRange:chunkRange]];
				
				didRespondToDataRequest = dataRequest.currentOffset >= (dataRequest.requestedOffset + dataRequest.requestedLength);
			}
		}
	}
	
	if (didRespondToDataRequest && didRespondToInformationRequest) {
		NSLog(@"Did handle loading request. Requesting content info: %@. Requesting data: %@. Data request range: %.3f - %.3f MB. Request was provided with %.3f MBytes.",
			  request.contentInformationRequest ? @"YES" : @"NO",
			  request.dataRequest ? @"YES" : @"NO",
			  (float)request.dataRequest.requestedOffset / (1024 * 1024),
			  (float)(request.dataRequest.requestedOffset + request.dataRequest.requestedLength) / (1024 * 1024),
			  (float)(request.dataRequest.currentOffset - request.dataRequest.requestedOffset) / (1024 * 1024));

		return YES;
	} else {
		return NO;
	}
}

#pragma mark - Accessors

- (FYContentRequester *)contentRequesterForURL:(NSURL *)url cachedFilePath:(NSString *)path {
	for (FYContentRequester *requester in _contentRequesters) {
		NSURL *originalURL = [self modifySongURL:url withCustomScheme:requester.resourceURL.scheme];
		
		if ([requester.resourceURL isEqual:originalURL] &&
			[requester.cacheFilenamePath isEqualToString:path]) {
			return requester;
		}
	}
	
	return nil;
}

- (FYContentRequester *)contentRequesterForResourceLoader:(AVAssetResourceLoader *)loader {
	for (FYContentRequester *requester in _contentRequesters) {
		for (FYResourceLoader *resourceLoader in requester.resourceLoaders) {
			if ([resourceLoader.loader isEqual:loader]) {
				return requester;
			}
		}
	}
	
	return nil;
}

- (FYResourceLoader *)fyResourceLoaderForLoader:(AVAssetResourceLoader *)loader {
	for (FYContentRequester *requester in _contentRequesters) {
		FYResourceLoader *candidate = [self fyResourceLoaderForLoader:loader forRequester:requester];
		
		if (candidate) {
			return candidate;
		}
	}
	
	return nil;
}

- (FYResourceLoader *)fyResourceLoaderForLoader:(AVAssetResourceLoader *)loader forRequester:(FYContentRequester *)requester {
	for (FYResourceLoader *resourceLoader in requester.resourceLoaders) {
		if ([resourceLoader.loader isEqual:loader]) {
			return resourceLoader;
		}
	}
	
	return nil;
}

- (NSString *)temporaryFileSuffix {
	return @"~part";
}

- (NSString *)metadataFileSuffix {
	return @"~meta";
}

#pragma mark - SCNetworkReachability

- (void)determineIsNetworkReachableWithCallback:(FYReachabilityCallback)callback {
	if (_latestReachabilityFlags) {
		// If we have latest reachability flags -> use them.
		!callback ? : callback([self isReachableWithFlags:_latestReachabilityFlags]);
	} else {
		if (callback) {
			// Store callback, because network reachability isn't yet determined.
			[_networkReachableWaiters addObject:callback];
		}
	}
}

static void NetworkReachabilityCallBack(SCNetworkReachabilityRef target,
										SCNetworkReachabilityFlags flags,
										void *info) {
	FYContentProvider *self = (__bridge FYContentProvider *)(info);
	
	self->_latestReachabilityFlags = flags;

	NSArray *waiters = [self->_networkReachableWaiters copy];
	
	NSLog(@"[ContentProvider]: Network state changed. Is connected? %@", [self isReachableWithFlags:flags] ? @"YES" : @"NO");
	[self->_networkReachableWaiters removeAllObjects];
	
	for (FYReachabilityCallback reachabilityCallback in waiters) {
		reachabilityCallback([self isReachableWithFlags:flags]);
	}
}

- (BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags {
	SCNetworkReachabilityFlags airplaneFlags = kSCNetworkReachabilityFlagsConnectionRequired |
												kSCNetworkReachabilityFlagsTransientConnection;
	
	return (flags & kSCNetworkReachabilityFlagsReachable) &&
			((flags & airplaneFlags) != airplaneFlags);
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
	NSLog(@"Received loading request. Requesting content info: %@. Requesting data: %@. Data request range: %.3f - %.3f MB",
		  loadingRequest.contentInformationRequest ? @"YES" : @"NO",
		  loadingRequest.dataRequest ? @"YES" : @"NO",
		  (float)loadingRequest.dataRequest.requestedOffset / (1024 * 1024),
		  (float)(loadingRequest.dataRequest.requestedOffset + loadingRequest.dataRequest.requestedLength) / (1024 * 1024));
	
	FYContentRequester *requester = [self contentRequesterForResourceLoader:resourceLoader];
	FYResourceLoader *loader = [self fyResourceLoaderForLoader:resourceLoader forRequester:requester];
	
	// We need to satisfy latest request right here right now.
	if (loader.latestRequest) {
		BOOL didSatisfy = [self tryToSatisfyRequest:loader.latestRequest forRequester:requester];
		
		if (didSatisfy) {
			[loader.latestRequest finishLoading];
		} else {
			// TODO: Error
			[loader.latestRequest finishLoadingWithError:nil];
		}
		
		loader.latestRequest = nil;
	}
	
	// Try to satisfy NEW request right now.
	BOOL didSatisfy = [self tryToSatisfyRequest:loadingRequest forRequester:requester];
	
	if (didSatisfy) {
		[loadingRequest finishLoading];
	} else {
		// If we didn't satisfy request -> add it as pending request to process later.
		loader.latestRequest = loadingRequest;
		
		// If we're not streaming from cache and loading request is asking for data then:
		if (!requester.isStreamingFromCache && loadingRequest.dataRequest) {
			
//			if (requester.streamingState == kStreamingStateStreaming) {
//				
//			} else if (requester.streamingState == kStreamingStateOnDemand) {
//				
//			}
			
			if (requester.session.offset > loadingRequest.dataRequest.requestedOffset) {
				NSLog(@"[ContentProvider]: Resource loader is requesting data behind current session offset. Will transite to on-demand state.");
				// We've requested data behind current session offset.
				// Transite to on-demand state and resend request to server.
				requester.streamingState = kStreamingStateOnDemand;
				
				[requester.session startLoadingFromOffset:loadingRequest.dataRequest.requestedOffset
					entityTag:requester.metadataFile.etag];
			} else {
				NSInteger currentOffset = requester.session.offset + requester.session.downloadedData.length;
				NSInteger bytesToDownload = loadingRequest.dataRequest.requestedOffset - currentOffset;
				
				if (bytesToDownload > 0) {
					if (requester.streamingState == kStreamingStateOnDemand &&
						requester.session.connectionDate == nil) {
						// If we are already streaming on demand && we didn't connected yet -> restart connection from new offset.
						[requester.session startLoadingFromOffset:loadingRequest.dataRequest.requestedOffset
														entityTag:requester.metadataFile.etag];
					} else {
						// If we got some bytes to download -> check how much time it'll take.
						// If time > treshold value -> transite to on-demand state and begin fetching from requested offset.
						
						// Calculate average download speed and how much time we need to catch up with requested offset.
						NSTimeInterval timePassed = -[requester.session.connectionDate timeIntervalSinceNow];
						NSInteger totalBytesDownloaded = requester.session.downloadedData.length;
						
						CGFloat bytesPerSecond = totalBytesDownloaded / timePassed;
						
						CGFloat approximateTimeForSeeking = bytesToDownload / bytesPerSecond;
						NSLog(@"[ContentProvider]: Time passed: %.2fs. AVG: %.2f KBps. Approximate: %.2f (KBytes to download: %d)", timePassed, bytesPerSecond / 1024, approximateTimeForSeeking, (int32_t)bytesToDownload / 1024);
						
						if (approximateTimeForSeeking > kMaximumWaitingTimeTreshold ||
							isnan(approximateTimeForSeeking)) {
							NSLog(@"[ContentProvider]: Will transite to ON DEMAND state!");
							requester.streamingState = kStreamingStateOnDemand;
							
							[requester.session startLoadingFromOffset:loadingRequest.dataRequest.requestedOffset
															entityTag:requester.metadataFile.etag];
						} else {
							NSLog(@"[ContentProvider]: Will wait %.2f seconds...", approximateTimeForSeeking);
						}
					}
				}
			}
		}
	}

	return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
	FYResourceLoader *loader = [self fyResourceLoaderForLoader:resourceLoader];
	
	if ([loader.latestRequest isEqual:loadingRequest]) {
		loader.latestRequest = nil;
	}
}

@end