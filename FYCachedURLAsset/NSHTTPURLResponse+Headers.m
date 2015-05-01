//
//  NSHTTPURLResponse+Headers.m
//  FYCachedUrlAsset
//
//  Created by Vitaliy Ivanov on 4/30/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "NSHTTPURLResponse+Headers.h"

@implementation NSHTTPURLResponse (Headers)

- (NSString*)headerValueForKey:(NSString*)key
{
	for (NSString* existingKey in [self allHeaderFields])
	{
		if ([key compare:existingKey options:NSCaseInsensitiveSearch] == NSOrderedSame)
		{
			return [self allHeaderFields][existingKey];
		}
	}
	
	return nil;
}

@end
