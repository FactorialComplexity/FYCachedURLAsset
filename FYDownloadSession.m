//
//  FYDownloadSession.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/27/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "FYDownloadSession.h"

@interface FYDownloadSession ()
<
NSURLConnectionDataDelegate
>
@end

@implementation FYDownloadSession {
	NSMutableData *_downloadedData;
	
	NSURLConnection *_connection;
}

#pragma mark - Init

- (instancetype)initWithURL:(NSURL *)url {
	if (self = [super init]) {
		_resourceURL = url;
		
		_downloadedData = [NSMutableData new];
	}
	
	return self;
}

#pragma mark - Loading

- (void)startLoadingFromOffset:(NSInteger)offset entityTag:(NSString *)etag {
	// Cleanup if we already loading something.
	[self cancelLoading];
	
	// Build headers to request data from requested offset.
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resourceURL];
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;

	if (offset != 0) {
		NSString *range = [NSString stringWithFormat:@"bytes=%lu-", (unsigned long)offset];
		
		if (etag.length > 0) {
			[request setValue:etag forHTTPHeaderField:@"If-Range"];
		}
		
		[request setValue:range forHTTPHeaderField:@"Range"];
	}
	
	_offset = offset;
	_connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)startLoadingFrom:(NSInteger)from to:(NSInteger)to entityTag:(NSString *)etag {
	// Cleanup if we already loading something.
	[self cancelLoading];
	
	// Build headers to request data from requested offset.
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resourceURL];
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	NSString *range = [NSString stringWithFormat:@"bytes=%lu-%lu", (unsigned long)from, (unsigned long)to];
	
	if (etag.length > 0) {
		[request setValue:etag forHTTPHeaderField:@"If-Range"];
	}
	
	[request setValue:range forHTTPHeaderField:@"Range"];
	
	_offset = from;
	_connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)cancelLoading {
	[_connection cancel];
	_connection = nil;
	
	_downloadedData.length = 0;
	_offset = 0;
	_connectionDate = nil;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	NSLog(@"Response: %@", httpResponse);
	
	if (httpResponse.statusCode == 200 || httpResponse.statusCode == 206) {
		_response = (NSHTTPURLResponse *)response;
		_connectionDate = [NSDate date];
		
		BOOL shouldContinueDownload = YES;
		!self.responseBlock ? : self.responseBlock(_response, &shouldContinueDownload);
	} else {
		// TODO: Call failure block?
		[connection cancel];
	}	
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_downloadedData appendData:data];
	
	!self.chunkDownloadBlock ? : self.chunkDownloadBlock(data);
	// TODO: Testing
	static int failer = 0;
	failer++;
	if (failer == 10) {
		NSLog(@"Will FAIL!");
//		[connection cancel];
//		[self connection:connection didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain
//																		 code:0
//																	 userInfo:@{NSLocalizedDescriptionKey : @"TEST"}]];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"%s", __FUNCTION__);
	!self.successBlock ? : self.successBlock();
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"%s", __FUNCTION__);
	!self.failureBlock ? : self.failureBlock(error);
}

@end
