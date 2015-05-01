//
//  FYCachedURLAssetLog.h
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 5/1/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import <Foundation/Foundation.h>

#if CACHED_URL_ASSET_DEBUG_LOG || CACHED_URL_ASSET_VERBOSE_LOG
#	define FYLogD(fmt, ...) NSLog((@"(FYCachedURLAsset) D " fmt), ##__VA_ARGS__)
#else
#   define FYLogD(...)
#endif

#if CACHED_URL_ASSET_VERBOSE_LOG
#	define FYLogV(fmt, ...) NSLog((@"(FYCachedURLAsset) V " fmt), ##__VA_ARGS__)
#else
#	define FYLogV(fmt, ...)
#endif

#define FYLogI(fmt, ...) NSLog((@"(FYCachedURLAsset) I " fmt), ##__VA_ARGS__)
#define FYLogE(fmt, ...) NSLog((@"(FYCachedURLAsset) E " fmt), ##__VA_ARGS__)
