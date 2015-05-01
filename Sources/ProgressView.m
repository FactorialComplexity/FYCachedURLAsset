//
//  ProgressView.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/27/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "ProgressView.h"

@implementation ProgressView
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
