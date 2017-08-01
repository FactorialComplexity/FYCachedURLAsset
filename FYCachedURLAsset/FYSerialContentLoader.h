/*
 MIT License
 
 Copyright (c) 2015 Factorial Complexity
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

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
- (void)serialContentLoaderDidInvalidateCache:(FYSerialContentLoader*)loader withError:(NSError*)error;

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

- (void)removeCacheAndStopAllRequestsWithError:(NSError*)error;

- (void)stopDownloading;

@end
