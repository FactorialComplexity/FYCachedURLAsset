//
//  FYHEADRequest.h
//  FYCachedURLAssetTest
//
//  Created by Vitaliy Ivanov on 5/8/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FYHEADRequest : NSObject

- (id)initWithURL:(NSURL*)URL completion:(void(^)(NSHTTPURLResponse* response, NSError* error))completion;

- (void)cancel;

@end
