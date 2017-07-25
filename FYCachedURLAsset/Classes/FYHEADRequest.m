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
