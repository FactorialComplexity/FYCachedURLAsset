//
//  FYCachedStorage.h
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/23/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

@import Foundation;

/**
 *  TODO: This class is not needed in current version.
 */
@interface FYCachedStorage : NSObject

@property (nonatomic) NSArray *allCachedMediaFiles; // TODO:

+ (instancetype)shared;

/**
 *  Returns YES if file with given name exist.
 */
- (BOOL)fileExistWithName:(NSString *)name;

/**
 *  Creates file with given name or erases existing.
 */
- (NSFileHandle *)createFileWithName:(NSString *)name;

/**
 *  Tries to open file with given name for writing/reading.
 */
- (NSFileHandle *)openFileWithName:(NSString *)name;


// TODO: Remove below.
- (BOOL)cachedFileExistWithName:(NSString *)fileName;
- (NSFileHandle *)cachedMetadataFileForName:(NSString *)name;
- (NSFileHandle *)cachedFileWithName:(NSString *)name;


@end
