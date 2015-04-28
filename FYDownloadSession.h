//
//  FYDownloadSession.h
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/27/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import Foundation;

typedef void (^FYResponseBlock) (NSHTTPURLResponse *response, BOOL *shouldContinueDownload);
typedef void (^FYChunkDownloadBlock) (NSData *chunk);
typedef void (^FYSuccessBlock) ();
typedef void (^FYFailureBlock) (NSError *error);

@interface FYDownloadSession : NSObject

/**
 *  URL for resource.
 */
@property (nonatomic, readonly) NSURL *resourceURL;

/**
 *  Offset from which data has been downloaded.
 */
@property (nonatomic, readonly) NSInteger offset;

/**
 *  Data that was downloaded in current session.
 */
@property (nonatomic, readonly) NSData *downloadedData;

/**
 *  Date on which latest connection has been made.
 */
@property (nonatomic, readonly) NSDate *connectionDate;

/**
 *  Response for given session.
 */
@property (nonatomic, readonly) NSHTTPURLResponse *response;

/**
 *  Response block that is called when received response for given URL.
 */
@property (nonatomic, copy) FYResponseBlock responseBlock;

/**
 *  Block that is called per chunk of data received from server.
 */
@property (nonatomic, copy) FYChunkDownloadBlock chunkDownloadBlock;

/**
 *  Success block that is called when all data downloaded from server.
 */
@property (nonatomic, copy) FYSuccessBlock successBlock;

/**
 *  Failure block that is called if any error occured.
 */
@property (nonatomic, copy) FYFailureBlock failureBlock;

/**
 *  Creates download session with given URL.
 */
- (instancetype)initWithURL:(NSURL *)url;

/**
 *  Begins loading content from given URL from supplied offset for specific entity.
 *	If loading is currently in progress -> it will be restarted.
 */
- (void)startLoadingFromOffset:(NSInteger)offset entityTag:(NSString *)etag;
- (void)startLoadingFrom:(NSInteger)from to:(NSInteger)to entityTag:(NSString *)etag;
- (void)cancelLoading;

@end
