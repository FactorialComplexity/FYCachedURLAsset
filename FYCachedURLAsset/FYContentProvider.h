//
//  FYContentProvider.h
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 4/30/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import AVFoundation;

#define kFYResourceForURLChangedErrorCode	(-1000)

@class FYCachedURLAsset;
@class FYContentProvider;
@protocol FYContentProviderDelegate <NSObject>

- (void)contentProvider:(FYContentProvider*)contentProvider didFailWithPermanentError:(NSError*)permanentError;

@end


@interface FYContentProvider : NSObject <AVAssetResourceLoaderDelegate>

+ (FYContentProvider*)contentProviderWithURL:(NSURL*)URL cacheFilePath:(NSString*)cacheFilePath
	asset:(FYCachedURLAsset*)asset;

@property (nonatomic, readonly) NSURL* URL;
@property (nonatomic, readonly) NSString* cacheFilePath;

@property (nonatomic, readonly) long long contentLength;
@property (nonatomic, readonly) long long availableDataOnDisk;
@property (nonatomic, readonly) long long availableData;

@property (nonatomic, readonly) NSError* permanentError;

- (void)addAsset:(FYCachedURLAsset*)asset;
- (void)removeAsset:(FYCachedURLAsset*)asset;

@end
