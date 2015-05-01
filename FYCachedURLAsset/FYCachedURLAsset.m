//
//  FYCachedURLAsset.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/23/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "FYCachedURLAsset.h"
#import "FYContentProvider.h"
#import "FYCachedURLAssetLog.h"

NSString *const FYResourceForURLChangedNotificationName = @"FYResourceForURLChangedNotification";
NSString *const FYResourceForURLDoesntExistNotificationName = @"FYResourceForURLDoesntExistNotification";

@interface FYCachedURLAsset ()

@end

@implementation FYCachedURLAsset
{
	FYContentProvider* _contentProvider;
}

#pragma mark - Lifecycle

+ (instancetype)cachedURLAssetWithURL:(NSURL *)url cacheFilePath:(NSString *)path
{
	// Don't allow nil path.
	path = path.length > 0 ? path : @"";
	
	FYCachedURLAsset *asset = [[self alloc] initWithURL:url cacheFilePath:path];
	return asset;
}

- (instancetype)initWithURL:(NSURL*)URL cacheFilePath:(NSString*)cacheFilePath
{
	NSURL* customURL = [FYCachedURLAsset URL:URL withCustomScheme:@"streaming"];
	if (self = [super initWithURL:customURL options:@{ AVURLAssetReferenceRestrictionsKey : @(AVAssetReferenceRestrictionForbidAll) }])
	{
		FYLogD(@"ASSET INIT\n  URL: %@\n  cacheFilePath: %@", URL, cacheFilePath);
		
		_contentProvider = [FYContentProvider contentProviderWithURL:URL cacheFilePath:cacheFilePath assetResourceLoader:self.resourceLoader];
	}
	
	return self;
}

- (NSURL*)originalURL
{
	return _contentProvider.URL;
}

- (FYCachedURLAssetCacheInfo)cacheInfo
{
	FYCachedURLAssetCacheInfo info;
	info.contentLength = _contentProvider.contentLength;
	info.availableData = _contentProvider.availableData;
	info.availableDataOnDisk = _contentProvider.availableDataOnDisk;
	return info;
}

- (void)dealloc
{
	FYLogD(@"ASSET DEALLOC\n   URL: %@\n  cacheFilePath: %@", _contentProvider.URL, _contentProvider.cacheFilePath);
}

#pragma mark - Private

+ (NSURL*)URL:(NSURL *)url withCustomScheme:(NSString *)scheme
{
	NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
	components.scheme = scheme;
 
	return [components URL];
}

@end
