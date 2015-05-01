//
//  FYContentProvider.m
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 4/30/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "FYContentProvider.h"
#import "FYSerialContentLoader.h"
#import "FYRandomAccessContentLoader.h"
#import "FYCachedURLAssetLog.h"

@interface FYContentProvider () <FYSerialContentLoaderDelegate, FYRandomAccessContentLoaderDelegate>
{
	FYSerialContentLoader* _serialContentLoader;
	NSMutableSet* _randomAccessLoaders;
	NSMutableSet* _requestsForContentInformationOnly;
}

@end


@implementation FYContentProvider

+ (FYContentProvider*)contentProviderWithURL:(NSURL*)URL cacheFilePath:(NSString*)cacheFilePath
	assetResourceLoader:(AVAssetResourceLoader*)assetResourceLoader
{
	FYContentProvider* contentProvider = [[FYContentProvider alloc] initWithURL:URL cacheFilePath:cacheFilePath
		assetResourceLoader:assetResourceLoader];
	
	return contentProvider;
}

- (instancetype)initWithURL:(NSURL*)URL cacheFilePath:(NSString*)cacheFilePath assetResourceLoader:(AVAssetResourceLoader*)assetResourceLoader
{
	if ((self = [super init]))
	{
		_URL = URL;
		_cacheFilePath = cacheFilePath;
		
		_serialContentLoader = [[FYSerialContentLoader alloc] initWithURL:URL cacheFilePath:cacheFilePath
			delegate:self];
		_randomAccessLoaders = [[NSMutableSet alloc] init];
		_requestsForContentInformationOnly = [[NSMutableSet alloc] init];
		
		[assetResourceLoader setDelegate:self queue:dispatch_get_main_queue()];
	}
	
	return self;
}

- (void)dealloc
{
	[_serialContentLoader stopDownloading];
	for (FYRandomAccessContentLoader* loader in _randomAccessLoaders)
		[loader cancel];
	
	FYLogD(@"[FYContentProvider dealloc]\n   URL: %@\n  cacheFilePath: %@", _URL, _cacheFilePath);
}

- (void)addResourceLoadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest
{
	if (loadingRequest.dataRequest)
	{
		if (loadingRequest.dataRequest.requestedOffset <= (_serialContentLoader.availableData + 512*512))
			[_serialContentLoader addLoadingRequest:loadingRequest];
		else
		{
			FYRandomAccessContentLoader* randomAccessContentLoader = [[FYRandomAccessContentLoader alloc] initWithURL:_URL
				loadingRequest:loadingRequest delegate:self];
			[_randomAccessLoaders addObject:randomAccessContentLoader];
		}
	}
	else if (loadingRequest.contentInformationRequest)
	{
		[_requestsForContentInformationOnly addObject:loadingRequest];
	}
}

- (void)removeResourceLoadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest
{
	[_serialContentLoader removeLoadingRequest:loadingRequest];
	
	for (FYRandomAccessContentLoader* randomAccessLoader in _randomAccessLoaders)
	{
		if (randomAccessLoader.loadingRequest == loadingRequest)
		{
			[randomAccessLoader cancel];
			[_randomAccessLoaders removeObject:randomAccessLoader];
			break;
		}
	}
}

- (void)updateContentInformationRequest:(AVAssetResourceLoadingContentInformationRequest*)contentInformationRequest
{
	contentInformationRequest.contentType = _serialContentLoader.contentType;
	contentInformationRequest.byteRangeAccessSupported = YES;
	
	if (_serialContentLoader.contentLength > 0) // we know content length
		contentInformationRequest.contentLength = _serialContentLoader.contentLength;
}

- (long long)contentLength
{
	return _serialContentLoader.contentLength;
}

- (long long)availableDataOnDisk
{
	return _serialContentLoader.availableDataOnDisk;
}

- (long long)availableData
{
	return _serialContentLoader.availableData;
}

#pragma mark - FYRandomAccessContentLoaderDelegate

- (void)randomAccessContentLoaderDidFinishLoading:(FYRandomAccessContentLoader*)loader
{
	[_randomAccessLoaders removeObject:loader];
}

#pragma mark - FYSerialContentLoaderDelegate

- (void)serialContentLoaderDidUpdateMeta:(FYSerialContentLoader*)loader
{
	for (AVAssetResourceLoadingRequest* loadingRequest in _serialContentLoader.loadingRequests)
	{
		if (loadingRequest.contentInformationRequest)
			[self updateContentInformationRequest:loadingRequest.contentInformationRequest];
	}
	
	for (FYRandomAccessContentLoader* randomAccessLoader in _randomAccessLoaders)
	{
		if (randomAccessLoader.loadingRequest.contentInformationRequest)
			[self updateContentInformationRequest:randomAccessLoader.loadingRequest.contentInformationRequest];
	}
	
	for (AVAssetResourceLoadingRequest* loadingRequest in _requestsForContentInformationOnly)
	{
		[self updateContentInformationRequest:loadingRequest.contentInformationRequest];
		[loadingRequest finishLoading];
	}
	[_requestsForContentInformationOnly removeAllObjects];
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader*)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest*)loadingRequest
{
	FYLogD(@"NEW REQUEST (%llx)\n  Content information: %@\n  Offset: %lld\n  Length: %lld",
		(long long)loadingRequest,
		loadingRequest.contentInformationRequest ? @"Y" : @"N",
		loadingRequest.dataRequest ? loadingRequest.dataRequest.requestedOffset : 0,
		loadingRequest.dataRequest ? (long long)loadingRequest.dataRequest.requestedLength : 0);

	if (loadingRequest.contentInformationRequest)
	{
		if (_serialContentLoader.hasContentInformation)
			[self updateContentInformationRequest:loadingRequest.contentInformationRequest];
	}
	
	[self addResourceLoadingRequest:loadingRequest];
	return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader*)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest
{
	FYLogD(@"CANCEL REQUEST (%llx)", (long long)loadingRequest);
	
	[self removeResourceLoadingRequest:loadingRequest];
}

@end
