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

#import "FYProgressView.h"

@implementation FYProgressView
{
	FYCachedURLAssetCacheInfo _info;
}

#pragma mark - Public

- (void)updateWithCacheInfo:(FYCachedURLAssetCacheInfo)info {
	_info = info;
	[self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
	CGRect bounds = self.bounds;
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	[[UIColor grayColor] setFill];
	CGContextFillRect(ctx, rect);
	
	CGRect availableDataRect = (CGRect) {
		0,
		0,
		CGRectGetWidth(bounds) * ((float)_info.availableData / (float)_info.contentLength),
		CGRectGetHeight(bounds)
	};
	
	CGRect availableDataOnDiskRect = (CGRect) {
		0,
		0,
		CGRectGetWidth(bounds) * ((float)_info.availableDataOnDisk / (float)_info.contentLength),
		CGRectGetHeight(bounds)
	};
	
	[[UIColor blueColor] setFill];
	CGContextFillRect(ctx, availableDataRect);
	[[UIColor greenColor] setFill];
	CGContextFillRect(ctx, availableDataOnDiskRect);
}

@end
