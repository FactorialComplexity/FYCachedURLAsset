//
//  AVAssetResourceLoadingDataRequest+Info.h
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 5/1/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import AVFoundation;

@interface AVAssetResourceLoadingDataRequest (Info)

@property (readonly, nonatomic) long long leftLength;
@property (readonly, nonatomic, getter=isAllDataProvided) BOOL allDataProvided;

@end
