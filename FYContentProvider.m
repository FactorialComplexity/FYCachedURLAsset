//
//  FYContentLoader.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/23/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

// Model
#import "FYContentProvider.h"
#import "FYCachedURLAsset.h"
#import "FYCachedStorage.h"

// Frameworks
@import MobileCoreServices;
@import SystemConfiguration;

#define DEPRECATED_FLOW

#pragma mark - FYContentRequester

// TODO: Refactor totally.

@interface FYContentRequester : NSObject

@property (nonatomic) NSMutableArray *requestingAssets;
@property (nonatomic) BOOL isStreamingFromCache;
@property (nonatomic) NSMutableArray *pendingRequests;
@property (nonatomic) NSURL *originalURL;
@property (nonatomic) NSFileHandle *metadataFile;
@property (nonatomic) NSFileHandle *cachedFile;
@property (nonatomic) NSURLResponse *response;
@property (nonatomic) NSURLConnection *connection;
@property (nonatomic) NSMutableData *mediaData;

@property (nonatomic) NSURL *resourceURL;
@property (nonatomic) NSDate *connectionDate;

@end

@implementation FYContentRequester

- (instancetype)initWithURL:(NSURL *)resourceURL {
	if (self = [super init]) {
		_resourceURL = resourceURL;
		
		_pendingRequests = [NSMutableArray new];
		_mediaData = [NSMutableData new];
	}
	
	return self;
}

- (instancetype)init {
	if (self = [super init]) {
		_requestingAssets = [NSMutableArray new];
		_pendingRequests = [NSMutableArray new];
		_mediaData = [NSMutableData new];
	}
	return self;
}

@end

#pragma mark - FYContentProvider

typedef void (^FYReachabilityCallback) (BOOL isConnectedToTheInternet);

@interface FYContentProvider ()
<
AVAssetResourceLoaderDelegate
>
@end

@implementation FYContentProvider {
	// Reachability related.
	SCNetworkReachabilityRef _reachability;
	SCNetworkReachabilityFlags _latestReachabilityFlags;
	// General callback for reachability.
	FYReachabilityCallback _reachabilityCallback;
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

#pragma mark - Init

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
		
		_reachabilityCallback = ^(BOOL isReachable) {
			
		};
	}
	return self;
}

- (void)dealloc {
	// Thus it never happens, but this is good coding style to release allocated stuff.
	SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), NULL);
	CFRelease(_reachability);
}

#pragma mark - Public

- (void)startResourceLoadingFromURL:(NSURL *)url withResourceLoader:(AVAssetResourceLoader *)loader {
	[loader setDelegate:self queue:dispatch_get_main_queue()];
	
	// Check if we're already loading something from given URL.
	BOOL alreadyLoading = NO;
	
	for (FYContentRequester *requester in _contentRequesters) {
		if ([requester.resourceURL isEqual:url]) {
			alreadyLoading = YES;
		}
	}

	NSLog(@"Registering URL: %@. Already loading: %@", url, alreadyLoading ? @"YES" : @"NO");

	if (!alreadyLoading) {
		// We're not loading from given URL yet.
		FYContentRequester *requester = [[FYContentRequester alloc] initWithURL:url];
		
		[_contentRequesters addObject:requester];
		
		[self determineIsNetworkReachableWithCallback:^(BOOL isConnectedToTheInternet) {
			// 1. If we have internet connection & cached version -> check on server is cached version is up-to date.
			// 2. If we have internet connection & !cached version -> create temp file and download data into it.
			// 3. If we don't have internet connection -> check for cached version on disk. If it's present -> play it.
			if (isConnectedToTheInternet) {
				NSURLRequest *request = [NSURLRequest requestWithURL:url];
				requester.connection = [NSURLConnection connectionWithRequest:request delegate:self];
				[requester.connection start];
			} else {
				// Find cached version of file, otherwise we can't do anything here.
				
			}
		}];
	}
}

- (void)stopResourceLoadingFromURL:(NSURL *)url {
	// TODO:
	
}

- (void)registerAsset:(FYCachedURLAsset *)asset {
	[asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];

	BOOL alreadyCaching = NO;
	// Check if we already have the same asset requesting data.
	for (FYContentRequester *requester in _contentRequesters) {
		FYCachedURLAsset *anyAsset = [requester.requestingAssets firstObject];
		
		if ([anyAsset.originalURL isEqual:asset.originalURL]) {
			[requester.requestingAssets addObject:asset];
			
			alreadyCaching = YES;
			break;
		}
	}
	
	NSLog(@"Registering asset: %@ with URL: %@. Already caching: %@", asset, asset.originalURL, alreadyCaching ? @"YES" : @"NO");
	if (!alreadyCaching) {
		// Asset isn't registered yet.
		FYContentRequester *requester = [FYContentRequester new];
		NSString *cachedFilename = [[asset.originalURL absoluteString] lastPathComponent];
		NSString *filenameMetadata = [cachedFilename stringByAppendingString:@"~meta"];

		[requester.requestingAssets addObject:asset];
		requester.originalURL = asset.originalURL;
		requester.isStreamingFromCache = [[FYCachedStorage shared] cachedFileExistWithName:cachedFilename];
		requester.cachedFile = [[FYCachedStorage shared] cachedFileWithName:cachedFilename];
		requester.metadataFile = [[FYCachedStorage shared] cachedFileWithName:filenameMetadata];

		[_contentRequesters addObject:requester];
	}
}

- (void)unregisterAsset:(FYCachedURLAsset *)asset {
	[self invalidateForAsset:asset];
}

#pragma mark - Private

- (FYContentRequester *)contentRequesterForResourseLoader:(AVAssetResourceLoader *)loader {
	for (FYContentRequester *requester in _contentRequesters) {
		for (FYCachedURLAsset *asset in requester.requestingAssets) {
			if ([asset.resourceLoader isEqual:loader]) {
				return requester;
			}
		}
	}
	
	return nil;
}

- (FYContentRequester *)contentRequesterConnection:(NSURLConnection *)connection {
	for (FYContentRequester *requester in _contentRequesters) {
		if ([requester.connection isEqual:connection]) {
			return requester;
		}
	}
	
	return nil;
}

- (void)processAllPendingRequests {
	for (FYContentRequester *requester in _contentRequesters) {
		for (AVAssetResourceLoadingRequest *request in [requester.pendingRequests copy]) {
			BOOL didSatisfyRequest = [self tryToSatisfyRequest:request forRequester:requester];
			
			if (didSatisfyRequest) {
				[requester.pendingRequests removeObject:request];
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
		if (requester.response) {
			CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,
																			(__bridge CFStringRef)(requester.response.MIMEType),
																			NULL);
			
			request.contentInformationRequest.contentType = CFBridgingRelease(contentType);
			request.contentInformationRequest.contentLength = requester.response.expectedContentLength;
			request.contentInformationRequest.byteRangeAccessSupported = YES;
			
			didRespondToInformationRequest = YES;
		}
	}
	
	if (request.dataRequest) {
		AVAssetResourceLoadingDataRequest *dataRequest = request.dataRequest;
		NSData *availableData = requester.mediaData;
		
		if (dataRequest.currentOffset <= availableData.length) {
			CGFloat bytesGot = availableData.length - request.dataRequest.currentOffset;
			CGFloat bytesToGive = MIN(bytesGot, dataRequest.requestedOffset + dataRequest.requestedLength - dataRequest.currentOffset);
			
			NSRange requestedDataRange = (NSRange){
				request.dataRequest.currentOffset,
				bytesToGive
			};
			
			[request.dataRequest respondWithData:[availableData subdataWithRange:requestedDataRange]];
			
			// If we gave something - we've responded to that request.
			didRespondToDataRequest = bytesToGive > 0;
		}
	}
	
	if (didRespondToDataRequest && didRespondToInformationRequest) {
		NSLog(@"Did handle request: %@", request);
		[request finishLoading];
		
		return YES;
	} else {
		return NO;
	}
}

- (void)invalidateForAsset:(FYCachedURLAsset *)asset {
	for (FYContentRequester *requester in [_contentRequesters copy]) {
		[requester.requestingAssets removeObject:asset];
		
		if (requester.requestingAssets.count == 0) {
			[requester.connection cancel];
			
			[_contentRequesters removeObject:requester];
		}
	}
}

- (NSString *)temporaryFileSuffix {
	return @"~temp";
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
			[_networkReachableWaiters addObject:callback];
		}
	}
}

static void NetworkReachabilityCallBack(SCNetworkReachabilityRef target,
										SCNetworkReachabilityFlags flags,
										void *info) {
	FYContentProvider *self = (__bridge FYContentProvider *)(info);
	
	self->_latestReachabilityFlags = flags;
	!self->_reachabilityCallback ? : self->_reachabilityCallback([self isReachableWithFlags:flags]);

	NSArray *waiters = [self->_networkReachableWaiters copy];
	
	[self->_networkReachableWaiters removeAllObjects];
	
	for (FYReachabilityCallback reachabilityCallback in waiters) {
		reachabilityCallback([self isReachableWithFlags:flags]);
	}
}

- (BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags {
	// Airplane mode:
	SCNetworkReachabilityFlags airplaneFlags = kSCNetworkReachabilityFlagsConnectionRequired |
	kSCNetworkReachabilityFlagsTransientConnection;
	
	return (flags & kSCNetworkReachabilityFlagsReachable) &&
			((flags & airplaneFlags) != airplaneFlags);
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
//	NSLog(@"Wanted to wait for loading for request: %@", loadingRequest);
	
	FYContentRequester *requester = [self contentRequesterForResourseLoader:resourceLoader];

	BOOL didSatisfy = [self tryToSatisfyRequest:loadingRequest forRequester:requester];
	
	if (!didSatisfy) {
		[requester.pendingRequests addObject:loadingRequest];
		[self processAllPendingRequests];
	}
	
	if (!requester.isStreamingFromCache) {
		if (!requester.connection) {
			NSURLRequest *request = [NSURLRequest requestWithURL:requester.originalURL];
			requester.connection = [NSURLConnection connectionWithRequest:request
																 delegate:self];
		}
	} else {
		if (requester.mediaData.length == 0) {
			requester.cachedFile.readabilityHandler = ^(NSFileHandle *fileHandle) {
				NSData *readData = fileHandle.availableData;
				[fileHandle closeFile];

				dispatch_async(dispatch_get_main_queue(), ^{
					requester.mediaData = [readData mutableCopy];
					
					[self processAllPendingRequests];					
				});
			};
			
			requester.metadataFile.readabilityHandler = ^(NSFileHandle *fileHandle) {
				NSData *readData = fileHandle.availableData;
				[fileHandle closeFile];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					requester.response = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
					
					[self processAllPendingRequests];
				});
			};
		}
	}
	
	return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
	FYContentRequester *requester = [self contentRequesterForResourseLoader:resourceLoader];
	
	[requester.pendingRequests removeObject:loadingRequest];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
#ifdef DEPRECATED_FLOW
	FYContentRequester *requester = [self contentRequesterConnection:connection];

	requester.response = response;
	
	NSString *filename = [requester.originalURL.absoluteString lastPathComponent];
	NSString *filenameMetadata = [filename stringByAppendingString:@"~meta"];
	
	requester.metadataFile = [[FYCachedStorage shared] cachedFileWithName:filenameMetadata];
	
	[requester.metadataFile writeData:[NSKeyedArchiver archivedDataWithRootObject:response]];
	[requester.metadataFile closeFile];
	
	NSLog(@"Received response: %@", response);
#else

#endif
	
	// TODO: Move all code to private queue.
//	FYContentRequester *requester = [self contentRequesterConnection:connection];
	
	// Check if we already have cached file.
	
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	FYContentRequester *requester = [self contentRequesterConnection:connection];
	
	[requester.cachedFile writeData:data];
	[requester.mediaData appendData:data];
	
	[self processAllPendingRequests];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"%s", __FUNCTION__);
	[self processAllPendingRequests];
	
	FYContentRequester *requester = [self contentRequesterConnection:connection];
	
	// Synchronize file.
	[requester.cachedFile closeFile];
}

@end
