#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AVAssetResourceLoadingDataRequest+Info.h"
#import "FYCachedURLAsset.h"
#import "FYCachedURLAssetLog.h"
#import "FYContentProvider.h"
#import "FYHEADRequest.h"
#import "FYRandomAccessContentLoader.h"
#import "FYSerialContentLoader.h"
#import "NSHTTPURLResponse+Headers.h"

FOUNDATION_EXPORT double FYCachedURLAssetVersionNumber;
FOUNDATION_EXPORT const unsigned char FYCachedURLAssetVersionString[];

