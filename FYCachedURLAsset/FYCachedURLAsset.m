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

#import "FYCachedURLAsset.h"
#import "FYContentProvider.h"
#import "FYCachedURLAssetLog.h"

NSString *const FYResourceForURLChangedNotification = @"FYResourceForURLChangedNotification";
NSString *const FYResourceForURLDoesntExistNotificationName = @"FYResourceForURLDoesntExistNotification";

@interface FYCachedURLAsset ()

@end

@implementation FYCachedURLAsset
{
	FYContentProvider* _contentProvider;
	NSError* _permanentError;
	NSString* _cacheFilePath;
}

#pragma mark - Lifecycle

+ (instancetype)cachedURLAssetWithURL:(NSURL *)url cacheFilePath:(NSString *)path
{
	// Don't allow nil path.
	path = path.length > 0 ? path : @"";
	
	FYCachedURLAsset *asset = [[self alloc] initWithURL:url cacheFilePath:path];
	return asset;
}

- (instancetype)initWithURL:(NSURL*)URL cacheFilePath:(NSString*)cacheFilePath
{
	NSURL* customURL = [FYCachedURLAsset URL:URL withCustomScheme:@"streaming"];
	if (self = [super initWithURL:customURL options:@{ AVURLAssetReferenceRestrictionsKey : @(AVAssetReferenceRestrictionForbidAll) }])
	{
		FYLogD(@"ASSET INIT\n  URL: %@\n  cacheFilePath: %@", URL, cacheFilePath);
		
		_originalURL = URL;
		_cacheFilePath = cacheFilePath;
		_contentProvider = [FYContentProvider contentProviderWithURL:URL cacheFilePath:cacheFilePath asset:self];
	}
	
	return self;
}

- (FYCachedURLAssetCacheInfo)cacheInfo
{
	FYCachedURLAssetCacheInfo info;
	info.contentLength = _contentProvider.contentLength;
	info.availableData = _contentProvider.availableData;
	info.availableDataOnDisk = _contentProvider.availableDataOnDisk;
	return info;
}

- (void)cancel
{
	[_contentProvider cancel];
	
	[_contentProvider removeAsset:self];
}

- (void)removeCache
{
	[self cancel];
	
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@~part", _cacheFilePath] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@~meta", _cacheFilePath] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@", _cacheFilePath] error:nil];
}

- (void)dealloc
{
	[_contentProvider removeAsset:self];

	FYLogD(@"[FYCachedURLAsset dealloc]\n  URL: %@\n  cacheFilePath: %@", _originalURL, _cacheFilePath);
}

#pragma mark - FYContentProviderDelegate

- (void)failWithPermanentError:(NSError*)permanentError
{
	_contentProvider = nil;
	_permanentError = permanentError;
	
	if ([[_permanentError domain] isEqualToString:@"FYCachedURLAsset"] &&
		[_permanentError code] == kFYResourceForURLChangedErrorCode)
	{
		// resource updated
		[[NSNotificationCenter defaultCenter] postNotificationName:FYResourceForURLChangedNotification object:self];
	}
}

#pragma mark - Private

+ (NSURL*)URL:(NSURL *)url withCustomScheme:(NSString *)scheme
{
	NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
	components.scheme = scheme;
 
	return [components URL];
}

@end
