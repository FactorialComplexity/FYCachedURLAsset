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

extern NSString *const FYResourceForURLChangedNotification;
//extern NSString *const FYResourceForURLDoesntExistNotificationName;

typedef struct
{
	long long contentLength;
	long long availableData;
	long long availableDataOnDisk;
}
FYCachedURLAssetCacheInfo;

@interface FYCachedURLAsset : AVURLAsset

/**
 *  To allow caching we're doing some hacks with URL.
 *	These hacks force resource loader to ask for content.
 *	In this case you can't rely on regular URL property of AVAsset.
 *	Use originalURL instead.
 */
@property (nonatomic, readonly) NSURL *originalURL;

@property (nonatomic, readonly) FYCachedURLAssetCacheInfo cacheInfo;

/**
 *  Creates cached url asset instance with given url and given path.
 *	If path leads to some file then that means that this file is cached specially for given URL.
 *	If provide path to existing file that is not associated with given URL -> you'll get wrong behaviour.
 */
+ (instancetype)cachedURLAssetWithURL:(NSURL *)url cacheFilePath:(NSString *)path;

- (void)cancel;

@end
