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

// TODO: For testing
@property (nonatomic, copy) void (^progressBlock) (NSInteger startOffset, NSInteger localPresented, NSInteger downloaded, NSInteger totalBytesToDownload);

+ (instancetype)shared;

- (void)startResourceLoadingFromURL:(NSURL *)url toCachedFilePath:(NSString *)cachedFilePath
			withResourceLoader:(AVAssetResourceLoader *)loader;

- (void)stopResourceLoadingFromURL:(NSURL *)url cachedFilePath:(NSString *)cachedFilePath;

@end
