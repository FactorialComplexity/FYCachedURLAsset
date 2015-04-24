//
//  FYContentLoader.h
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/23/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import AVFoundation;

@class FYCachedURLAsset;

/**
 *  Content loader class that is responsible for providing content.
 */
@interface FYContentProvider : NSObject
<
AVAssetResourceLoaderDelegate
>

+ (instancetype)shared;

- (void)startResourceLoadingFromURL:(NSURL *)url withResourceLoader:(AVAssetResourceLoader *)loader;
- (void)stopResourceLoadingFromURL:(NSURL *)url;

/**
 *  Register asset that wants data.
 */
- (void)registerAsset:(FYCachedURLAsset *)asset;

/**
 *
 */
- (void)unregisterAsset:(FYCachedURLAsset *)asset;

@end
