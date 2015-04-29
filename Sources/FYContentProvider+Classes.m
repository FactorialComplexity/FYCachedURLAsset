//
//  FYContentProvider+Classes.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/29/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "FYContentProvider+Classes.h"
#import "FYDownloadSession.h"

@import MobileCoreServices;

#pragma mark - FYResourceLoader

@implementation FYResourceLoader

- (instancetype)initWithLoader:(AVAssetResourceLoader *)loader {
	if (self = [super init]) {
		_loader = loader;
	}
	return self;
}

@end

#pragma mark - FYCachedFileMeta

@implementation FYCachedFileMeta

#pragma mark - Init

- (instancetype)initWithResponse:(NSHTTPURLResponse *)response fromSession:(FYDownloadSession *)session {
	if (self = [super init]) {
		_etag = response.allHeaderFields[@"ETag"];
		
		CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,
																		(__bridge CFStringRef)(response.MIMEType),
																		NULL);
		_mimeType = CFBridgingRelease(contentType);
		
		_contentLength = response.expectedContentLength + session.offset;
	}
	
	return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		_etag = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(etag))];
		_mimeType = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(mimeType))];
		_contentLength = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(contentLength))];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:_etag forKey:NSStringFromSelector(@selector(etag))];
	[aCoder encodeObject:_mimeType forKey:NSStringFromSelector(@selector(mimeType))];
	[aCoder encodeInteger:_contentLength forKey:NSStringFromSelector(@selector(contentLength))];
}

@end

#pragma mark - FYContentRequester

@implementation FYContentRequester

#pragma mark - Lifecycle

- (instancetype)initWithURL:(NSURL *)resourceURL cacheFilePath:(NSString *)path resourceLoader:(AVAssetResourceLoader *)loader {
	if (self = [super init]) {
		_session = [[FYDownloadSession alloc] initWithURL:resourceURL];
		_cacheFilenamePath = path;
		
		_resourceURL = resourceURL;
		_localData = [NSMutableData new];
		_resourceLoaders = [NSMutableArray new];
		
		_totalRequestersCount = 1;
		
		FYResourceLoader *resourceLoader = [[FYResourceLoader alloc] initWithLoader:loader];
		[_resourceLoaders addObject:resourceLoader];
	}
	
	return self;
}

- (void)dealloc {
	// Testing memory leaks.
	NSLog(@"%s", __FUNCTION__);
}

@end