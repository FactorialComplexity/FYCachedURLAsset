//
//  FYCachedURLAsset.h
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/23/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import AVFoundation;

typedef void (^ProgressBlock) (CGFloat totalProgress);

@interface FYCachedURLAsset : AVURLAsset

/**
 *  To allow caching we're doing some hacks with URL.
 *	These hacks force resource loader to ask for content.
 *	In this case you can't rely on regular URL property of AVAsset.
 *	Use originalURL instead.
 */
@property (nonatomic, readonly) NSURL *originalURL;

/**
 *  Creates cached url asset instance with given url and given path.
 *	If path leads to some file then that means that this file is cached specially for given URL.
 *	If provide path to existing file that is not associated with given URL -> you'll get wrong behaviour.
 */
+ (instancetype)cachedURLAssetWithURL:(NSURL *)url
						cacheFilePath:(NSString *)path;

@end
