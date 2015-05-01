//
//  FYContentProvider.h
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 4/30/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import AVFoundation;

@interface FYContentProvider : NSObject <AVAssetResourceLoaderDelegate>

+ (FYContentProvider*)contentProviderWithURL:(NSURL*)URL cacheFilePath:(NSString*)cacheFilePath
	assetResourceLoader:(AVAssetResourceLoader*)assetResourceLoader;

@property (nonatomic, readonly) NSURL* URL;
@property (nonatomic, readonly) NSString* cacheFilePath;

@property (nonatomic, readonly) long long contentLength;
@property (nonatomic, readonly) long long availableDataOnDisk;
@property (nonatomic, readonly) long long availableData;

@end
