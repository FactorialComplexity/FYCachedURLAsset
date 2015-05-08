//
//  FYHEADRequest.m
//  FYCachedURLAssetTest
//
//  Created by Vitaliy Ivanov on 5/8/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "FYHEADRequest.h"

@interface FYHEADRequest () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
	NSURLConnection* _connection;
	void(^_completion)(NSHTTPURLResponse* response, NSError* error);
}

@end


@implementation FYHEADRequest

- (id)initWithURL:(NSURL*)URL completion:(void(^)(NSHTTPURLResponse* response, NSError* error))completion
{
	if ((self = [super init]))
	{
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
		[request setHTTPMethod:@"HEAD"];
		
		_completion = completion;
		_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
	}
	
	return self;
}

- (void)cancel
{
	[_connection cancel];
	_connection = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
	_completion(response, nil);
	
	[_connection cancel];
	_connection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	_completion(nil, error);
}

@end
