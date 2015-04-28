//
//  ProgressView.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/27/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "ProgressView.h"

@implementation ProgressView

#pragma mark - Public

- (void)flush {
	[self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	[[UIColor grayColor] setFill];
	CGContextFillRect(ctx, rect);
	
	if (self.totalProgress == 0) {
		return;
	}
	
	CGFloat localToFill = (float)self.locallyPresented / self.totalProgress;
	CGFloat howMuchToFill = (float)self.currentProgress / self.totalProgress;
	
	CGRect localRect = (CGRect) {
		0,
		0,
		CGRectGetWidth(rect) * localToFill,
		CGRectGetHeight(rect)
	};
	
	CGRect progressRect = (CGRect) {
		(float)self.startOffsetProgress / self.totalProgress * CGRectGetWidth(rect),
		0,
		CGRectGetWidth(rect) * howMuchToFill,
		CGRectGetHeight(rect)
	};
	
	[[UIColor greenColor] setFill];
	CGContextFillRect(ctx, localRect);
	[[UIColor blueColor] setFill];
	CGContextFillRect(ctx, progressRect);
}

@end
