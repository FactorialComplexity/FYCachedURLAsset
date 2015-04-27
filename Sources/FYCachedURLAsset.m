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

@interface FYCachedURLAsset ()
<
AVAssetResourceLoaderDelegate,
NSURLConnectionDataDelegate
>
@end

@implementation FYCachedURLAsset {
	NSURL *_originalURL;
}

#pragma mark - Init

+ (instancetype)cachedURLAssetWithURL:(NSURL *)url
						cacheFilePath:(NSString *)path {

	FYCachedURLAsset *asset = [[self alloc] initWithURL:url
									options:@{AVURLAssetReferenceRestrictionsKey : @(AVAssetReferenceRestrictionForbidAll)}];

	[[FYContentProvider shared] startResourceLoadingFromURL:url toCachedFilePath:path withResourceLoader:asset.resourceLoader];
	
	return asset;
}

- (instancetype)initWithURL:(NSURL *)URL options:(NSDictionary *)options {
	NSURL *customURL = [self modifySongURL:URL withCustomScheme:@"streaming"];
	
	if (self = [super initWithURL:customURL options:options]) {
		_originalURL = URL;
	}
	
	return self;
}

- (void)dealloc {
	[[FYContentProvider shared] stopResourceLoadingFromURL:self.originalURL];
}

#pragma mark - Private

- (NSURL *)modifySongURL:(NSURL *)url withCustomScheme:(NSString *)scheme {
	NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
	components.scheme = scheme;
 
	return [components URL];
}

@end
