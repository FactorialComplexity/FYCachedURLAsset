//
//  FYContentLoader.h
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 5/1/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import AVFoundation;

typedef NS_ENUM(NSInteger, FYContentState)
{
	FYContentStateNotLoaded = 0,
	FYContentStatePartial,
	FYContentStateFull
};


@class FYSerialContentLoader;
@protocol FYSerialContentLoaderDelegate <NSObject>

- (void)serialContentLoaderDidUpdateMeta:(FYSerialContentLoader*)loader;

@end


@interface FYSerialContentLoader : NSObject

- (instancetype)initWithURL:(NSURL*)URL cacheFilePath:(NSString*)cacheFilePath
	delegate:(id<FYSerialContentLoaderDelegate>)delegate;

@property (readonly, nonatomic) FYContentState contentState;
@property (readonly, nonatomic) BOOL hasContentInformation;

@property (readonly, nonatomic) NSString* contentType;
@property (readonly, nonatomic) long long contentLength;
@property (readonly, nonatomic) NSString* eTag;

@property (readonly, nonatomic) NSSet* loadingRequests;
@property (readonly, nonatomic) long long availableData;
@property (nonatomic, readonly) long long availableDataOnDisk;

- (void)addLoadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest;
- (void)removeLoadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest;

- (void)stopDownloading;

@end
