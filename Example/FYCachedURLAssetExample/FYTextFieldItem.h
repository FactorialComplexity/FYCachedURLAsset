//
//  FYTextViewItem.h
//  FYCachedURLAssetExample
//
//  Created by Viktor Naryshkin on 7/26/17.
//  Copyright © 2017 Viktor Naryshkin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FYTableCellItem.h"

@interface FYTextFieldItem : NSObject <FYTableCellItem>

@property (nonatomic) NSString *text;
@property (nonatomic) NSString *placeholder;
    
- (instancetype)initWithText:(NSString*)text placeholder:(NSString*)placeholder;
    
@end
