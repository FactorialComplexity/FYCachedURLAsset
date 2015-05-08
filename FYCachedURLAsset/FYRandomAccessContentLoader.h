//
//  FYRandomAccessContentLoader.h
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 5/1/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import AVFoundation;

@class FYRandomAccessContentLoader;
@protocol FYRandomAccessContentLoaderDelegate <NSObject>

- (void)randomAccessContentLoaderDidFinishLoading:(FYRandomAccessContentLoader*)loader;
- (void)randomAccessContentLoaderDidInvalidateCache:(FYRandomAccessContentLoader*)loader withError:(NSError*)error;
- (BOOL)hasETagForRandomAccessContentLoader:(FYRandomAccessContentLoader*)loader;
- (NSString*)eTagForRandomAccessContentLoader:(FYRandomAccessContentLoader*)loader;

@end


@interface FYRandomAccessContentLoader : NSObject

- (instancetype)initWithURL:(NSURL*)URL loadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest
	delegate:(id<FYRandomAccessContentLoaderDelegate>)delegate;

- (void)cancel;

@property (readonly, nonatomic) NSURL* URL;
@property (readonly, nonatomic) AVAssetResourceLoadingRequest* loadingRequest;

@end
