//
//  ProgressView.h
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/27/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import UIKit;

/**
 *  Non-flexible class for visualization purposes.
 */
@interface ProgressView : UIView

@property (nonatomic) NSInteger startOffsetProgress;
@property (nonatomic) NSInteger locallyPresented;
@property (nonatomic) NSInteger currentProgress;
@property (nonatomic) NSInteger totalProgress;

- (void)flush;

@end
