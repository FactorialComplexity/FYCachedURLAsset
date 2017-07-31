/*
 MIT License
 
 Copyright (c) 2015 Factorial Complexity
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "FYMediaItem.h"

@implementation FYMediaItem

static NSString *MediaNameArchiveKey = @"mediaName";
static NSString *MediaUrlArchiveKey = @"mediaUrl";
static NSString *MediaSizeArchiveKey = @"mediaSize";
static NSString *MediaLengthArchiveKey = @"mediaLength";
    
@synthesize itemType;
    
- (instancetype)initWithMediaName:(NSString*)mediaName mediaUrl:(NSString*)mediaUrl mediaSize:(int64_t)mediaSize mediaLength:(int32_t)mediaLength {
    if (self = [super init]) {
        _mediaName = mediaName;
        _mediaURL = mediaUrl;
		_mediaSize = mediaSize;
		_mediaLength = mediaLength;
    }
    
    return self;
}

- (NSString*)mediaSizeReadable {
	return [self sizeToReadableString:_mediaSize];
}

- (NSString*)mediaLengthReadable {
	return [self lengthToReadableString:_mediaLength];
}

- (BOOL)hasMediaSize {
	return _mediaSize > 0;
}

- (BOOL)hasMediaLength {
	return _mediaLength > 0;
}

#pragma mark - Private

- (NSString*)sizeToReadableString:(int64_t)bytes {
	return [NSString stringWithFormat:@"%.01f MB", bytes / 1024.0 / 1024.0];
}

- (NSString*)lengthToReadableString:(int32_t)seconds {
	int hours = seconds / 3600;
	int remainder = seconds % 3600;
	int minutes = remainder / 60;
	seconds = remainder % 60;
	
	if (hours > 0) {
		return [NSString stringWithFormat:@"%dh %dm %ds", hours, minutes, seconds];
	} else if (minutes > 0) {
		return [NSString stringWithFormat:@"%dm %ds", minutes, seconds];
	} else {
		return [NSString stringWithFormat:@"%ds", seconds];
	}
}

#pragma mark - <NSCoding>

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self != nil) {
		_mediaName = [decoder decodeObjectForKey:MediaNameArchiveKey];
		_mediaURL = [decoder decodeObjectForKey:MediaUrlArchiveKey];
		_mediaSize = [decoder decodeInt64ForKey:MediaSizeArchiveKey];
		_mediaLength = [decoder decodeInt32ForKey:MediaLengthArchiveKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:_mediaName forKey:MediaNameArchiveKey];
	[encoder encodeObject:_mediaURL forKey:MediaUrlArchiveKey];
	[encoder encodeInt64:_mediaSize forKey:MediaSizeArchiveKey];
	[encoder encodeInt32:_mediaLength forKey:MediaLengthArchiveKey];
}

@end
