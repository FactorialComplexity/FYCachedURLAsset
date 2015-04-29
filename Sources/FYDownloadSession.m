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
	
	// Tag that is supplied by caller.
	NSString *_currentEntityTag;
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
	
	_currentEntityTag = etag;
	
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
	
	_currentEntityTag = etag;
	
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
	
	_currentEntityTag = nil;
	
	_downloadedData.length = 0;
	_offset = 0;
	_connectionDate = nil;
}

#pragma mark - Public

- (void)fetchEntityTagForResourceWithSuccess:(FYSuccessWithETagBlock)success failure:(FYFailureBlock)failure {
	NSMutableURLRequest *headRequest = [NSMutableURLRequest requestWithURL:self.resourceURL];
	headRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;

	headRequest.HTTPMethod = @"HEAD";
	
	[NSURLConnection sendAsynchronousRequest:headRequest queue:[NSOperationQueue new]
		completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
			// We've requested head, so data won't be filled in.
			if (!connectionError) {
				NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
				
				if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
					dispatch_async(dispatch_get_main_queue(), ^{
						!success ? : success(httpResponse.allHeaderFields[@"ETag"]);
					});
				} else {
					NSString *localizedDescription = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
					
					if (!localizedDescription) {
						localizedDescription = @"Unknown error";
					}
					
					NSError *localizedError = [NSError errorWithDomain:NSCocoaErrorDomain
																  code:httpResponse.statusCode
															  userInfo:@{NSLocalizedDescriptionKey : localizedDescription}];
					
					dispatch_async(dispatch_get_main_queue(), ^{
						!failure ? : failure(localizedError);
					});
				}
			} else {
				dispatch_async(dispatch_get_main_queue(), ^{
					!failure ? : failure(connectionError);
				});
			}
	}];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	
	if (_currentEntityTag.length > 0) {
		// Check is resource changed while downloading.
		if (![httpResponse.allHeaderFields[@"ETag"] isEqualToString:_currentEntityTag]) {
			[self cancelLoading];
			
			!self.resourceChangedBlock ? : self.resourceChangedBlock();
			return;
		}
	}
	
	if (httpResponse.statusCode == 200 || httpResponse.statusCode == 206) {
		_response = (NSHTTPURLResponse *)response;
		_connectionDate = [NSDate date];
		
		!self.responseBlock ? : self.responseBlock(_response);
	} else {
		[connection cancel];
		
		// TODO: More introspection. We should build error for status codes that are not included in 200-299 range
		NSString *localizedDescription = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
		NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:httpResponse.statusCode
										 userInfo:@{NSLocalizedDescriptionKey : localizedDescription}];
		
		!self.failureBlock ? : self.failureBlock(error);
	}	
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_downloadedData appendData:data];
	
	!self.chunkDownloadBlock ? : self.chunkDownloadBlock(data);
	
	// TODO: Emulating failure.
//	static int failer = 0;
//	failer++;
//	if (failer == 10) {
//		NSLog(@"Will FAIL!");
//		[connection cancel];
//		[self connection:connection didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain
//																		 code:0
//																	 userInfo:@{NSLocalizedDescriptionKey : @"TEST"}]];
//	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	!self.successBlock ? : self.successBlock();
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	!self.failureBlock ? : self.failureBlock(error);
}

@end
