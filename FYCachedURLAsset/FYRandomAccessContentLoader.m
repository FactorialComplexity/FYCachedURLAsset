//
//  FYRandomAccessContentLoader.m
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 5/1/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "FYRandomAccessContentLoader.h"
#import "FYContentProvider.h"
#import "NSHTTPURLResponse+Headers.h"
#import "AVAssetResourceLoadingDataRequest+Info.h"
#import "FYCachedURLAssetLog.h"

@interface FYRandomAccessContentLoader ()
{
	__weak id<FYRandomAccessContentLoaderDelegate> _delegate;
	
	NSURLConnection* _connection;
}

@end


@implementation FYRandomAccessContentLoader

- (instancetype)initWithURL:(NSURL*)URL loadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest
	delegate:(id<FYRandomAccessContentLoaderDelegate>)delegate
{
	if ((self = [super init]))
	{
		_URL = URL;
		_loadingRequest = loadingRequest;
		_delegate = delegate;
		
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_URL];
		request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
		
		NSString* range = [NSString stringWithFormat:@"bytes=%llu-%llu",
			_loadingRequest.dataRequest.requestedOffset,
			(long long)(_loadingRequest.dataRequest.requestedOffset + _loadingRequest.dataRequest.requestedLength - 1)];
		[request setValue:range forHTTPHeaderField:@"Range"];
		
		_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
		
		FYLogD(@"RANDOM ACCESS LOADER INIT\n  URL: %@\n  request: %llx\n  offset: %lld\n  length: %lld\n",
			_URL, (long long)_loadingRequest, _loadingRequest.dataRequest.requestedOffset, (long long)_loadingRequest.dataRequest.requestedLength);
	}
	
	return self;
}

- (void)dealloc
{
	FYLogD(@"[FYRandomAccessContentLoader dealloc]\n   URL: %@\n  request: %llx", _URL, (long long)_loadingRequest);
}

- (void)cancel
{
	[_connection cancel];
	_connection = nil;
}

- (void)setDownloadingError:(NSError*)error
{
	_connection = nil;
	[_loadingRequest finishLoadingWithError:error];
	[_delegate randomAccessContentLoaderDidFinishLoading:self];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response
{
	FYLogD(@"RANDOM ACCESS LOADER HTTP RESPONSE HEADER\n  URL: %@\n  statusCode: %d\n  Content-Length: %lld\n  Content-Type: %@\n  ETag: %@",
		_URL, (int)response.statusCode, response.expectedContentLength,
		[response headerValueForKey:@"Content-Type"], [response headerValueForKey:@"ETag"]);
	
	NSString* currentETag = [_delegate eTagForRandomAccessContentLoader:self];
	NSString* newETag = [response headerValueForKey:@"ETag"];
	
	if ([_delegate hasETagForRandomAccessContentLoader:self] && ![currentETag isEqualToString:newETag])
	{
		// ETag changed and cached content should be invalidated
		FYLogD(@"SERIAL LOADER CACHE INVALIDATED\n  URL: %@\n  ETag (old): %@\n  ETag (new): %@",
			_URL, currentETag, newETag);
		
		NSError* cacheError = [[NSError alloc] initWithDomain:@"FYCachedURLAsset" code:kFYResourceForURLChangedErrorCode
			userInfo:@{
				NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Resource changed on server", @"")],
				@"ETag_Old": currentETag ? currentETag : [NSNull null],
				@"ETag_New": newETag ? newETag : [NSNull null],
			}];
		
		[_connection cancel];
		_connection = nil;
		
		[_delegate randomAccessContentLoaderDidInvalidateCache:self withError:cacheError];
		
		return;
	}

	
	if (response.statusCode >= 200 && response.statusCode < 300)
	{
		if (_loadingRequest.contentInformationRequest)
			_loadingRequest.contentInformationRequest.contentType = [response headerValueForKey:@"Content-Type"];
	}
	else
	{
		[self setDownloadingError:[[NSError alloc] initWithDomain:@"FYCachedURLAsset" code:response.statusCode
			userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Web server responded with HTTP error code %d", @""),
			(int)response.statusCode] }]];
	}
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)chunk
{
//	FYLogV(@"RANDOM ACCESS LOADER HTTP RESPONSE DATA\n  URL: %@\n  length: %lld\n  progress:  %lld of %lld",
//		_URL, (long long)[chunk length], _availableData + [chunk length], _contentLength);

	AVAssetResourceLoadingDataRequest* dataRequest = _loadingRequest.dataRequest;
	if (dataRequest.leftLength >= chunk.length)
		[dataRequest respondWithData:chunk];
	else
		[dataRequest respondWithData:[chunk subdataWithRange:NSMakeRange(0, (NSUInteger)dataRequest.leftLength)]];
	
	FYLogV(@"RANDOM ACCESS LOADER DATA FROM NETWORK\n  URL: %@\n  request: %llx\n  length: %lld\n  progress:  %lld of %lld",
		_URL, (long long)_loadingRequest, MIN((long long)[chunk length], dataRequest.leftLength), (long long)(dataRequest.currentOffset - dataRequest.requestedOffset),
		(long long)dataRequest.requestedLength);
	
	if (dataRequest.isAllDataProvided)
	{
		FYLogD(@"RANDOM ACCESS LOADER REQUEST COMPLETED\n  URL: %@\n  request: %llx",
			_URL, (long long)_loadingRequest);
	
		[_loadingRequest finishLoading];
		[_connection cancel];
		[_delegate randomAccessContentLoaderDidFinishLoading:self];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
	[_loadingRequest finishLoading];
	_connection = nil;
	[_delegate randomAccessContentLoaderDidFinishLoading:self];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
	[self setDownloadingError:error];
}

@end
