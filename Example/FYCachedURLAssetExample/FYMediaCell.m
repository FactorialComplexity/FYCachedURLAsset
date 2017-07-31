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

#import "FYMediaCell.h"

@implementation FYMediaCell {
	__weak IBOutlet UILabel *_mediaNameLabel;
	__weak IBOutlet UILabel *_mediaSizeLabel;
	__weak IBOutlet UILabel *_mediaDescriptionSeparatorLabel;
	__weak IBOutlet UILabel *_mediaLengthLabel;
	__weak IBOutlet UIImageView *_mediaCachedImage;
}

#pragma mark - Dynamic Properties

- (void)setItem:(FYMediaItem *)item {
	_media = item;
	
	[self setMediaName:item.mediaName];
	_mediaSizeLabel.text = item.mediaSizeReadable;
	_mediaLengthLabel.text = item.mediaLengthReadable;
	
	_mediaSizeLabel.hidden = !item.hasMediaSize;
	_mediaLengthLabel.hidden = !item.hasMediaLength;
	
	_mediaDescriptionSeparatorLabel.hidden = _mediaSizeLabel.hidden && _mediaLengthLabel.hidden;

	self.isCached = [[NSFileManager defaultManager] fileExistsAtPath:_media.cacheFilePath];
}

- (void)setMediaName:(NSString*)name {
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:name];
	[attributedString addAttribute:NSKernAttributeName
							 value:@(0.5)
							 range:NSMakeRange(0, attributedString.length)];
	
	_mediaNameLabel.attributedText = attributedString;
}

- (void)setIsCached:(BOOL)isCached {
	_isCached = isCached;
	
	_mediaCachedImage.hidden = !isCached;
}

@end
