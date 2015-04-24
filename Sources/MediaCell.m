//
//  MediaCell.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/24/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "MediaCell.h"

@implementation MediaCell {
	__weak IBOutlet UILabel *_mediaNameLabel;
	__weak IBOutlet UILabel *_mediaURLLabel;
	__weak IBOutlet UILabel *_stateLabel;
}

#pragma mark - Dynamic Properties

- (void)setMediaName:(NSString *)mediaName {
	_mediaName = mediaName;
	
	_mediaNameLabel.text = mediaName;
}

- (void)setMediaURL:(NSString *)mediaURL {
	_mediaURL = mediaURL;
	
	_mediaURLLabel.text = mediaURL;
}

- (void)setIsCached:(BOOL)isCached {
	_isCached = isCached;
	
	_stateLabel.text = isCached ? @"Cached" : @"Streaming";
}

@end
