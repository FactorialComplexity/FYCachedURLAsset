//
//  MediaCell.h
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/24/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import UIKit;

@interface MediaCell : UITableViewCell

@property (nonatomic) NSString *mediaName;
@property (nonatomic) NSString *mediaURL;
@property (nonatomic) BOOL isCached;

@end
