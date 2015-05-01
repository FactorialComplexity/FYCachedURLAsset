//
//  NSHTTPURLResponse+Headers.h
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 4/30/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSHTTPURLResponse (Headers)

- (NSString*)headerValueForKey:(NSString*)key;

@end
