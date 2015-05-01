//
//  FYDownloadSession.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/27/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "FYDownloadRequest.h"

@interface FYDownloadRequest () <NSURLConnectionDataDelegate>

@end


@implementation FYDownloadRequest
{
	NSURLConnection *_connection;
	
	// Tag that is supplied by caller.
	NSString *_currentEntityTag;
}

#pragma mark - Init

- (instancetype)initWithURL:(NSURL *)url
{
	if (self = [super init])
	{
		_resourceURL = url;
	}
	
	return self;
}

#pragma mark - Loading

- (void)startLoadingFromOffset:(NSInteger)offset entityTag:(NSString *)etag
{
	// Cleanup if we already loading something.
	[self cancelLoading];
	
	_currentEntityTag = etag;
	
	// Build headers to request data from requested offset.
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resourceURL];
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;

	if (offset != 0)
	{
		NSString *range = [NSString stringWithFormat:@"bytes=%lu-", (unsigned long)offset];
		
		if (etag.length > 0)
		{
			[request setValue:etag forHTTPHeaderField:@"If-Range"];
		}
		
		[request setValue:range forHTTPHeaderField:@"Range"];
	}
	
	_offset = offset;
	
	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
	[_connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	[_connection start];
}

- (void)startLoadingFrom:(NSInteger)from to:(NSInteger)to entityTag:(NSString *)etag {
	// Cleanup if we already loading something.
	[self cancelLoading];
	
	_currentEntityTag = etag;
	
	// Build headers to request data from requested offset.
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resourceURL];
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	NSString *range = [NSString stringWithFormat:@"bytes=%lu-%lu", (unsigned long)from, (unsigned long)to];
	
	if (etag.length > 0)
	{
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
	
	_offset = 0;
	_connectionDate = nil;
}

#pragma mark - Public

- (void)fetchEntityTagForResourceWithSuccess:(FYSuccessWithETagBlock)success failure:(FYFailureBlock)failure
{
	NSMutableURLRequest *headRequest = [NSMutableURLRequest requestWithURL:self.resourceURL];
	headRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;

	headRequest.HTTPMethod = @"HEAD";
	
	[NSURLConnection sendAsynchronousRequest:headRequest queue:[NSOperationQueue new]
		completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
	{
		// We've requested head, so data won't be filled in.
		if (!connectionError)
		{
			NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
			
			if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300)
			{
				dispatch_async(self.processingQueue ? self.processingQueue : dispatch_get_main_queue(), ^
				{
					!success ? : success(httpResponse.allHeaderFields[@"ETag"]);
				});
			}
			else
			{
				NSString *localizedDescription = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
				
				if (!localizedDescription)
				{
					localizedDescription = @"Unknown error";
				}
				
				NSError *localizedError = [NSError errorWithDomain:NSCocoaErrorDomain code:httpResponse.statusCode
					userInfo:@{NSLocalizedDescriptionKey : localizedDescription}];
				
				dispatch_async(self.processingQueue ? self.processingQueue : dispatch_get_main_queue(), ^
				{
					!failure ? : failure(localizedError, httpResponse.statusCode);
				});
			}
		}
		else
		{
			dispatch_async(self.processingQueue ? self.processingQueue : dispatch_get_main_queue(), ^
			{
				!failure ? : failure(connectionError, 0);
			});
		}
	}];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	dispatch_sync(self.processingQueue ? self.processingQueue : dispatch_get_main_queue(), ^
	{
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
		_response = httpResponse;
		
		if (_currentEntityTag.length > 0)
		{
			// Check is resource changed while downloading.
			if (![httpResponse.allHeaderFields[@"ETag"] isEqualToString:_currentEntityTag])
			{
				[self cancelLoading];
				
				!self.resourceChangedBlock ? : self.resourceChangedBlock();
				
				return;
			}
		}
		
		if (httpResponse.statusCode == 200 || httpResponse.statusCode == 206)
		{
			_response = (NSHTTPURLResponse *)response;
			_connectionDate = [NSDate date];
			
			!self.responseBlock ? : self.responseBlock(_response);
		}
		else
		{
			[connection cancel];
			
			// TODO: More introspection. We should build error for status codes that are not included in 200-299 range
			NSString *localizedDescription = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
			NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:httpResponse.statusCode
											 userInfo:@{NSLocalizedDescriptionKey : localizedDescription}];
			
			!self.failureBlock ? : self.failureBlock(error, httpResponse.statusCode);
		}
	});
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	dispatch_sync(self.processingQueue ? self.processingQueue : dispatch_get_main_queue(), ^
	{
		!self.chunkDownloadBlock ? : self.chunkDownloadBlock(data);
	});
	
	// Emulating failure.
//	static int failer = 0;
//	failer++;
//	if (failer == 15) {
//		NSLog(@"Will FAIL!");
//		[connection cancel];
//		[self connection:connection didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain
//																		 code:0
//																	 userInfo:@{NSLocalizedDescriptionKey : @"TEST"}]];
//	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	dispatch_sync(self.processingQueue ? self.processingQueue : dispatch_get_main_queue(), ^
	{
		!self.successBlock ? : self.successBlock();
	});
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	dispatch_sync(self.processingQueue ? self.processingQueue : dispatch_get_main_queue(), ^
	{
		!self.failureBlock ? : self.failureBlock(error, 0);
	});
}

@end
