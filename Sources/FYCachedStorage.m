//
//  FYCachedStorage.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/23/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

#import "FYCachedStorage.h"

#pragma mark - FYCachedFileInfo

@interface FYCachedFileInfo : NSObject
<
NSCoding
>

/**
 *	Path to cached file.
 */
@property (nonatomic) NSString *cachedFilePath;

/**
 *  URL to remote server on which given file is stored.
 */
@property (nonatomic) NSURL *remoteURL;

@end

@implementation FYCachedFileInfo

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	
}

@end

#pragma mark - FYCachedStorage

@implementation FYCachedStorage {
	NSMutableArray *_cachedFilesInfo;
}

#pragma mark - Singleton

+ (instancetype)shared {
	static id manager = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		manager = [self new];
	});
	
	return manager;
}

#pragma mark - Init

- (instancetype)init {
	if (self = [super init]) {
		// TODO: Move to bg.
		[self loadCachedDatabase];
	}
	
	return self;
}

#pragma mark - Public

- (BOOL)fileExistWithName:(NSString *)name {
	NSString *filePath = [self cachedDirectoryByAppendingPathComponent:name];
	
	return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (NSFileHandle *)createFileWithName:(NSString *)name {
	NSString *filePath = [self cachedDirectoryByAppendingPathComponent:name];
	
	if (![self fileExistWithName:name]) {
		BOOL didCreate = [[NSFileManager defaultManager] createFileAtPath:filePath
																 contents:nil
															   attributes:nil];
		if (!didCreate) {
			NSLog(@"[Warning]: Failed to create file for caching at path: '%@'!", name);
		}
	}
	
	return [self openFileWithName:name];
}

- (NSFileHandle *)openFileWithName:(NSString *)name {
	return [NSFileHandle fileHandleForWritingAtPath:[self cachedDirectoryByAppendingPathComponent:name]];
}

// TODO: Remove methods below

- (NSFileHandle *)cachedMetadataFileForName:(NSString *)name {
	// TODO:
	return nil;
}

- (BOOL)cachedFileExistWithName:(NSString *)fileName {
	NSString *filePath = [[self cachedDirectoryPath] stringByAppendingPathComponent:fileName];

	return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (NSFileHandle *)cachedFileWithName:(NSString *)name {
	NSString *filePath = [[self cachedDirectoryPath] stringByAppendingPathComponent:name];
	
	if (![self cachedFileExistWithName:name]) {
		BOOL didCreate = [[NSFileManager defaultManager] createFileAtPath:filePath
																 contents:nil
															   attributes:nil];
		if (!didCreate) {
			NSLog(@"[Warning]: Failed to create file for caching!");
		}
	}
	
	return [NSFileHandle fileHandleForUpdatingAtPath:filePath];
}

#pragma mark - Paths

- (NSString *)cachedDirectoryPath {
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
																NSUserDomainMask,
																YES) firstObject];
	NSString *cachedMediaPath = [cachesPath stringByAppendingPathComponent:@"CachedMedia"];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:cachedMediaPath]) {
		NSError *error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:cachedMediaPath withIntermediateDirectories:NO attributes:nil error:&error];
		
		if (error) {
			NSLog(@"[Warning]: Failed to create CachedMedia directory with error: %@", error);
		}
	}
	
	return cachedMediaPath;
}

- (NSString *)cachedDirectoryByAppendingPathComponent:(NSString *)path {
	return [[self cachedDirectoryPath] stringByAppendingPathComponent:path];
}

- (NSString *)allCachedFilesDBFilePath {
	NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
																   NSUserDomainMask,
																   YES) firstObject];
	
	NSString *dbPath = [documentsPath stringByAppendingString:@"CachedMedia.cdb"];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
		BOOL didCreate = [[NSFileManager defaultManager] createFileAtPath:dbPath contents:nil attributes:nil];
		
		if (!didCreate) {
			NSLog(@"[Warning]: Failed to create database file for cached media!");
		}
	}
	
	return dbPath;
}

#pragma mark - Database Management

- (void)loadCachedDatabase {
	NSString *dbPath = [self allCachedFilesDBFilePath];
	
	NSMutableArray *cachedFilesInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:dbPath];
	
	// Remove all files that are not stored in our db.
//	for (FYCachedFileInfo *cachedFileInfo in cachedFilesInfo) {
//	}
	
	if (!_cachedFilesInfo) {
		_cachedFilesInfo = [NSMutableArray new];
	}
}

- (void)saveToCachedDatabase {
	NSString *dbPath = [self allCachedFilesDBFilePath];
	
	NSData *bytes = [NSKeyedArchiver archivedDataWithRootObject:_cachedFilesInfo];
	
	[bytes writeToFile:dbPath atomically:NO];
}

@end