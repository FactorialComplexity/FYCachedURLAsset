//
//  FYCachedURLAsset.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/23/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

// Model
#import "FYCachedURLAsset.h"
#import "FYContentProvider.h"

NSString *const FYResourceForURLChangedNotificationName = @"FYResourceForURLChangedNotification";
NSString *const FYResourceForURLDoesntExistNotificationName = @"FYResourceForURLDoesntExistNotification";

@interface FYCachedURLAsset ()
<
AVAssetResourceLoaderDelegate,
NSURLConnectionDataDelegate
>
@end

@implementation FYCachedURLAsset {
	NSURL *_originalURL;
	NSString *_cachedFilePath;
}

#pragma mark - Lifecycle

+ (instancetype)cachedURLAssetWithURL:(NSURL *)url
						cacheFilePath:(NSString *)path {
	// Don't allow nil path.
	path = path.length > 0 ? path : @"";
	
	FYCachedURLAsset *asset = [[self alloc] initWithURL:url cacheFilePath:path];
	
	[[FYContentProvider shared] startResourceLoadingFromURL:url toCachedFilePath:path withResourceLoader:asset.resourceLoader];
	
	return asset;
}

- (instancetype)initWithURL:(NSURL *)URL cacheFilePath:(NSString *)path {
	NSURL *customURL = [self modifySongURL:URL withCustomScheme:@"streaming"];
	
	if (self = [super initWithURL:customURL options:@{AVURLAssetReferenceRestrictionsKey : @(AVAssetReferenceRestrictionForbidAll)}]) {
		_originalURL = URL;
		_cachedFilePath = path;
	}
	
	return self;
}

- (void)dealloc {
	[[FYContentProvider shared] stopResourceLoadingFromURL:self.originalURL cachedFilePath:_cachedFilePath];
}

#pragma mark - Private

- (NSURL *)modifySongURL:(NSURL *)url withCustomScheme:(NSString *)scheme {
	NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
	components.scheme = scheme;
 
	return [components URL];
}

@end
