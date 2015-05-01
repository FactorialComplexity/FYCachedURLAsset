//
//  ProgressView.h
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/27/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import UIKit;

#import "FYCachedURLAsset.h"

/**
 *  Non-flexible class for visualization purposes.
 */
@interface ProgressView : UIView

- (void)updateWithCacheInfo:(FYCachedURLAssetCacheInfo)info;

@end
