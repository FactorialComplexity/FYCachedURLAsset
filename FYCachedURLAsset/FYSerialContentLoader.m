//
//  FYContentLoader.m
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 5/1/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "FYSerialContentLoader.h"
#import "NSHTTPURLResponse+Headers.h"
#import "AVAssetResourceLoadingDataRequest+Info.h"
#import "FYCachedURLAssetLog.h"

@interface FYSerialContentLoader ()
{
	NSURL* _URL;
	NSString* _cacheFilePath;
	
	NSFileHandle* _file;
	long long _availableDataOnDisk;
	long long _availableData;
	
	NSURLConnection* _connection;
	dispatch_queue_t _workQueue;
	
	NSMutableSet* _loadingRequests;
	
	__weak id<FYSerialContentLoaderDelegate> _delegate;
}

@end


@implementation FYSerialContentLoader

- (instancetype)initWithURL:(NSURL*)URL cacheFilePath:(NSString*)cacheFilePath delegate:(id<FYSerialContentLoaderDelegate>)delegate
{
	if ((self = [super init]))
	{
		_URL = URL;
		_cacheFilePath = cacheFilePath;
		_delegate = delegate;
		
		_loadingRequests = [[NSMutableSet alloc] init];
		
		_contentLength = -1; // unknown content length
		
		NSFileManager* fm = [NSFileManager defaultManager];
		
		if ([fm fileExistsAtPath:[_cacheFilePath stringByAppendingString:@"~meta"]])
		{
			NSError* error;
			NSDictionary* meta = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[_cacheFilePath stringByAppendingString:@"~meta"]]
				options:0 error:&error];
			if ([meta isKindOfClass:[NSDictionary class]])
			{
				_hasContentInformation = YES;
				
				_contentType = meta[@"Content-Type"];
				_contentLength = [meta[@"Content-Length"] longLongValue];
				_eTag = meta[@"ETag"];
			}
		}
		
		if ([fm fileExistsAtPath:_cacheFilePath])
		{
			_contentState = FYContentStateFull;
			_file = [NSFileHandle fileHandleForUpdatingAtPath:_cacheFilePath];
			_contentLength = _availableData = _availableDataOnDisk = [_file seekToEndOfFile];
		}
		else if ([fm fileExistsAtPath:[_cacheFilePath stringByAppendingString:@"~part"]])
		{
			_contentState = FYContentStatePartial;
			
			_file = [NSFileHandle fileHandleForUpdatingAtPath:[_cacheFilePath stringByAppendingString:@"~part"]];
			_availableData = _availableDataOnDisk = [_file seekToEndOfFile];
		}
		else
		{
			[fm createFileAtPath:[_cacheFilePath stringByAppendingString:@"~part"] contents:nil attributes:nil];
			_file = [NSFileHandle fileHandleForUpdatingAtPath:[_cacheFilePath stringByAppendingString:@"~part"]];
		}
		
		_workQueue = dispatch_queue_create("com.f17y.FYContentCache", DISPATCH_QUEUE_SERIAL);
		
		FYLogD(@"SERIAL LOADER INIT\n  URL: %@\n  cacheFilePath: %@\n  contentState: %@\n  contentType: %@\n  contentLength: %lld\n  availableDataOnDisk: %lld",
			URL, cacheFilePath, _contentState == FYContentStateNotLoaded ? @"NotLoaded" :
				(_contentState == FYContentStateFull ? @"Full" : @"Partial"),
			_contentType, _contentLength, _availableDataOnDisk);
	}
	
	return self;
}

- (void)dealloc
{
	FYLogD(@"[FYSerialContentLoader dealloc]\n   URL: %@\n  cacheFilePath: %@", _URL, _cacheFilePath);
}

- (void)startDownloading
{
	if (_contentState != FYContentStateFull && !_connection)
	{
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_URL];
		request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
		
		unsigned long long offset = _availableData;
		if (offset != 0)
		{
			NSString *range = [NSString stringWithFormat:@"bytes=%llu-", offset];
			[request setValue:range forHTTPHeaderField:@"Range"];
		}
		
		FYLogD(@"SERIAL LOADER START DOWNLOADING\n  URL: %@\n  range: %lld-", _URL, offset);
		
		_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
	}
}

- (void)stopDownloading
{
	FYLogD(@"SERIAL LOADER STOP DOWNLOADING\n  URL: %@", _URL);
	
	[_connection cancel];
	_connection = nil;
}

- (void)addLoadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest
{
	[_loadingRequests addObject:loadingRequest];
	[self scheduleNextChunkFromDiskForRequest:loadingRequest];
	[self startDownloading];
}

- (void)removeLoadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest
{
	[_loadingRequests removeObject:loadingRequest];
	[self tryStopLoadingAfterDelay];
}

- (void)tryStopLoadingAfterDelay
{
	// stop loading after a small delay
	__weak typeof(self) wself = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
	{
		typeof(self) sself = wself;
		if (!sself)
			return;
		
		if ([sself->_loadingRequests count] == 0)
			[sself stopDownloading];
	});
}

- (void)checkRequestForCompletion:(AVAssetResourceLoadingRequest*)request
{
	if (request.dataRequest.isAllDataProvided || // completed and returned all the requested data
		request.dataRequest.currentOffset == _contentLength) // completed and returned all possible data (requested more than we can have)
	{
		FYLogD(@"SERIAL LOADER REQUEST COMPLETED\n  URL: %@\n  request: %llx",
			_URL, (long long)request);
	
		[_loadingRequests removeObject:request];
		[request finishLoading];
		[self tryStopLoadingAfterDelay];
	}
}

- (void)scheduleNextChunkFromDiskForRequest:(AVAssetResourceLoadingRequest*)request
{
	AVAssetResourceLoadingDataRequest* dataRequest = request.dataRequest;
	if (dataRequest.currentOffset < _availableDataOnDisk)
	{
		__weak typeof(self) wself = self;
		dispatch_async(_workQueue, ^
		{
			typeof(self) sself = wself;
			if (!sself)
				return;
		
			[sself->_file seekToFileOffset:dataRequest.currentOffset];
			NSData* chunk = [sself->_file readDataOfLength:MIN(MIN(sself->_availableDataOnDisk, dataRequest.leftLength), 512*1024)];
			
			dispatch_sync(dispatch_get_main_queue(), ^
			{
				typeof(self) sself = wself;
				if (!sself)
					return;
				
				if ([sself->_loadingRequests containsObject:request]) // if we still need this request
				{
					[dataRequest respondWithData:chunk];
					
					FYLogV(@"SERIAL LOADER DATA FROM DISK\n  URL: %@\n  request: %llx\n  length: %lld\n  progress:  %lld of %lld",
						sself->_URL, (long long)request, (long long)[chunk length], (long long)(dataRequest.currentOffset - dataRequest.requestedOffset),
						(long long)dataRequest.requestedLength);
					
					[sself checkRequestForCompletion:request];
					
					if (!request.isFinished)
						[sself scheduleNextChunkFromDiskForRequest:request];
				}
			});
		});
	}
}

- (void)setContentType:(NSString*)contentType contentLength:(long long)contentLength
{
	if (![_contentType isEqualToString:contentType] || _contentLength != contentLength)
	{
		_contentLength = contentLength;
		_contentType = contentType;
		
		NSMutableDictionary* dict = [NSMutableDictionary dictionary];
		if (_contentLength >= 0)
			dict[@"Content-Length"] = @(_contentLength);
		if (_contentType)
			dict[@"Content-Type"] = _contentType;
		
		NSError* error;
		[[NSJSONSerialization dataWithJSONObject:dict options:0 error:&error]
			writeToFile:[_cacheFilePath stringByAppendingString:@"~meta"] atomically:YES];
		
		[_delegate serialContentLoaderDidUpdateMeta:self];
	}
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response
{
	FYLogD(@"SERIAL LOADER HTTP RESPONSE HEADER\n  URL: %@\n  statusCode: %d\n  Content-Length: %lld\n  Content-Type: %@",
		_URL, (int)response.statusCode, response.expectedContentLength, [response headerValueForKey:@"Content-Type"]);
	
	if (response.statusCode >= 200 && response.statusCode < 300)
	{
		// we always request data from whatever we already have available to the very end,
		// so Content-Length (expectedContentLength) + _availableData is the total length of content
		[self setContentType:[response headerValueForKey:@"Content-Type"]
			contentLength:_availableData + response.expectedContentLength];
	}
	
	// TODO: error processing
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)chunk
{
//	FYLogD(@"SERIAL LOADER HTTP RESPONSE DATA\n  URL: %@\n  length: %lld\n  progress:  %lld of %lld",
//		_URL, (long long)[chunk length], _availableData + [chunk length], _contentLength);

	_availableData += [chunk length];
	
	__weak typeof(self) wself = self;
	dispatch_async(_workQueue, ^
	{
		typeof(self) sself = wself;
		if (!sself)
			return;
	
		[sself->_file seekToEndOfFile];
		[sself->_file writeData:chunk];
		
		dispatch_sync(dispatch_get_main_queue(), ^
		{
			typeof(self) sself = wself;
			if (!sself)
				return;
				
			long long previousAvailableDataOnDisk = sself->_availableDataOnDisk;
			sself->_availableDataOnDisk += [chunk length];
			
			if (sself->_availableDataOnDisk == sself->_contentLength)
			{
				FYLogI(@"SERIAL LOADER COMPLETED DOWNLOAD\n  URL: %@\n  Content-Length: %lld",
					sself->_URL, sself->_contentLength);
				
				[sself stopDownloading];
			
				NSError* error = nil;
				if (![[NSFileManager defaultManager] moveItemAtPath:[sself->_cacheFilePath stringByAppendingString:@"~part"] toPath:sself->_cacheFilePath error:&error])
					FYLogE(@"SERIAL LOADER FAILED FILE MOVE\n  from: %@\n  to: %@\n  error: %@",
						[sself->_cacheFilePath stringByAppendingString:@"~part"], sself->_cacheFilePath, error);
				else
					sself->_file = [NSFileHandle fileHandleForUpdatingAtPath:sself->_cacheFilePath];
			}
			
			NSSet* loadingRequestsCopy = [NSSet setWithSet:sself->_loadingRequests];
			for (AVAssetResourceLoadingRequest* request in loadingRequestsCopy)
			{
				AVAssetResourceLoadingDataRequest* dataRequest = request.dataRequest;
				if (dataRequest.currentOffset == previousAvailableDataOnDisk)
				{
					if (dataRequest.leftLength >= chunk.length)
						[dataRequest respondWithData:chunk];
					else
						[dataRequest respondWithData:[chunk subdataWithRange:NSMakeRange(0, dataRequest.leftLength)]];
					
					FYLogV(@"SERIAL LOADER DATA FROM NETWORK\n  URL: %@\n  request: %llx\n  length: %lld\n  progress:  %lld of %lld",
						sself->_URL, (long long)request, MIN((long long)[chunk length], dataRequest.leftLength), (long long)(dataRequest.currentOffset - dataRequest.requestedOffset),
						(long long)dataRequest.requestedLength);
					
					[sself checkRequestForCompletion:request];
				}
				else if (dataRequest.currentOffset >= previousAvailableDataOnDisk &&
					dataRequest.currentOffset < sself->_availableDataOnDisk)
				{
					// this request was previosly paused because we didn't have enough data,
					// but now we have it, although it is not aligned with current http request,
					// so we need to start disk fetching first
					[sself scheduleNextChunkFromDiskForRequest:request];
				}
			}
		});
	});
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
	[self stopDownloading];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
	// TODO: error processing
	[self stopDownloading];
}

@end
