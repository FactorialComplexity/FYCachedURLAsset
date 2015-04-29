//
//  FYContentProvider+Classes.h
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/29/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import AVFoundation;

@class FYDownloadSession;

#pragma mark - FYResourceLoader

@interface FYResourceLoader : NSObject

@property (nonatomic) AVAssetResourceLoader *loader;
@property (nonatomic) AVAssetResourceLoadingRequest *latestRequest;

- (instancetype)initWithLoader:(AVAssetResourceLoader *)loader;

@end

#pragma mark - FYCachedFileMeta

@interface FYCachedFileMeta : NSObject
<
NSCoding
>

@property (nonatomic, readonly) NSString *etag;
@property (nonatomic, readonly) NSString *mimeType;
@property (nonatomic, readonly) NSInteger contentLength;

- (instancetype)initWithResponse:(NSHTTPURLResponse *)response fromSession:(FYDownloadSession *)session;

@end

#pragma mark - FYContentRequester

typedef enum {
	// Regular streaming (over internet) or from cached file.
	kStreamingStateStreaming,
	// Streaming on demand (without caching). This happens when user wants to seek to specific times.
	kStreamingStateOnDemand
} StreamingState;

@interface FYContentRequester : NSObject

/**
 *  Current streaming state for content requester.
 */
@property (nonatomic) StreamingState streamingState;

/**
 *  Download session associated with given requester.
 */
@property (nonatomic) FYDownloadSession *session;

/**
 *  Original resource URL from which should be cached.
 */
@property (nonatomic) NSURL *resourceURL;

/**
 *  Cache filename path to which data should be stored from resourceURL.
 */
@property (nonatomic) NSString *cacheFilenamePath;

/**
 *  Array of FYResourceLoader instances that contain resource loader and latest request for it.
 *	(They should be equal to total requesters count)
 */
@property (nonatomic) NSMutableArray *resourceLoaders;

/**
 *  Total count of current requesters. Act like a reference counting mechanism.
 *	When it drops to zero it's treated as no one needs content from given URL.
 *	In this case content requester deallocates and performs cleanup.
 */
@property (nonatomic) NSInteger totalRequestersCount;

/**
 *  Tells if current content provider is streaming data from local storage.
 */
@property (nonatomic) BOOL isStreamingFromCache;

/**
 *  Media data that is gathered from cached file.
 */
@property (nonatomic) NSData *localData;

/**
 *  Contiguos media data that may be assembled in cached file later.
 */
@property (nonatomic) NSMutableData *contiguousData;

/**
 *  Metadata file for given requester.
 */
@property (nonatomic) FYCachedFileMeta *metadataFile;

- (instancetype)initWithURL:(NSURL *)url cacheFilePath:(NSString *)cachedFilePath resourceLoader:(AVAssetResourceLoader *)loader;

@end