//
//  AVAssetResourceLoadingDataRequest+Info.m
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 5/1/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "AVAssetResourceLoadingDataRequest+Info.h"

@implementation AVAssetResourceLoadingDataRequest (Info)

- (long long)leftLength
{
	return self.requestedLength - (self.currentOffset - self.requestedOffset);
}

- (BOOL)isAllDataProvided
{
	return self.leftLength == 0;
}

@end
