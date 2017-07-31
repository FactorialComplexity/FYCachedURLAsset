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

#import "FYHomeViewController.h"
#import "FYPlaybackViewController.h"

// Models
#import "FYCachedURLAsset.h"
#import "FYContentProvider.h"
#import "FYTableCellItem.h"
#import "FYHeaderItem.h"
#import "FYSectionItem.h"
#import "FYMediaItem.h"
#import "FYTextFieldItem.h"
#import "FYSeparatorItem.h"

// Cells
#import "FYTableViewCell.h"
#import "FYHeaderCell.h"
#import "FYSectionItem.h"
#import "FYMediaCell.h"
#import "FYTextFieldCell.h"
#import "FYSeparatorCell.h"

@interface FYHomeViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>
@end

@implementation FYHomeViewController {
	NSArray<id<FYTableCellItem>> *_rowsDatasource;
	
	NSMutableArray<FYMediaItem*>* _userMediaFiles;
	
    __weak IBOutlet UITableView *_tableView;
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self loadMediaFiles];

	[self updateDatasource];
	
	_tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 40;
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	[tap setCancelsTouchesInView:NO];
	[self.view addGestureRecognizer:tap];
}

#pragma mark - Callbacks

- (void)dismissKeyboard {
	[self.view endEditing:YES];
}

#pragma mark - Private

- (NSString*)documentDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

- (void)loadMediaFiles {
	NSData* mediaFilesData = [NSData dataWithContentsOfFile:[[self documentDirectory] stringByAppendingPathComponent:@"media.plist"]];
	
	if (mediaFilesData) {
		_userMediaFiles = [NSKeyedUnarchiver unarchiveObjectWithData:mediaFilesData];
	}

	if (!_userMediaFiles) {
		_userMediaFiles = [NSMutableArray new];
	}
}

- (void)saveMediaFiles {
	NSData* mediaFilesData = [NSKeyedArchiver archivedDataWithRootObject:_userMediaFiles];
	
	[mediaFilesData writeToFile:[[self documentDirectory] stringByAppendingPathComponent:@"media.plist"] atomically:YES];
}

- (void)updateDatasource {
    NSMutableArray<id<FYTableCellItem>>* rowsDatasource = [NSMutableArray new];
	
	[rowsDatasource addObject:[[FYHeaderItem alloc] initWithText:@"FY Cached URL Asset"]];
    
    [rowsDatasource addObject:[[FYSectionItem alloc] initWithText:@"MEDIA FILES EXAMPLES"]];
	
	[rowsDatasource addObject:[FYSeparatorItem new]];
    
    [rowsDatasource addObject:[[FYMediaItem alloc] initWithMediaName:@"Wave.mp3" mediaUrl:@"http://www.sample-videos.com/audio/mp3/wave.mp3" mediaSize:725240 mediaLength:45]];
	
	[rowsDatasource addObject:[FYSeparatorItem new]];
	
    [rowsDatasource addObject:[[FYMediaItem alloc] initWithMediaName:@"Big Buck Bunny.mp4" mediaUrl:@"http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_10mb.mp4" mediaSize:10498677 mediaLength:62]];
	
	[rowsDatasource addObject:[FYSeparatorItem new]];
	
    [rowsDatasource addObject:[[FYMediaItem alloc] initWithMediaName:@"Big Buck Bunny.mp4" mediaUrl:@"http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_30mb.mp4" mediaSize:31491130 mediaLength:170]];
	
	[rowsDatasource addObject:[FYSeparatorItem new]];
    
    [rowsDatasource addObject:[[FYSectionItem alloc] initWithText:@"YOUR MEDIA FILES"]];
	
	[rowsDatasource addObject:[FYSeparatorItem new]];
	
	for (FYMediaItem* mediaFile in _userMediaFiles) {
		[rowsDatasource addObject:mediaFile];
		
		[rowsDatasource addObject:[FYSeparatorItem new]];
	}
    
    [rowsDatasource addObject:[[FYTextFieldItem alloc] initWithText:nil placeholder:@"Past URL to add Media File"]];
    
    _rowsDatasource = [rowsDatasource copy];
	
	[_tableView reloadData];
}

- (void)addMediaFileWithUrl:(NSURL*)url {
	if (url && [url scheme] && [url host]) {
		NSString* mediaName = ([url lastPathComponent].length > 0) ? [url lastPathComponent] : [url absoluteString];
		
		FYMediaItem* mediaItem = [[FYMediaItem alloc] initWithMediaName:mediaName mediaUrl:[url absoluteString] mediaSize:0 mediaLength:0];
		
		[_userMediaFiles addObject:mediaItem];
		
		[self saveMediaFiles];
		
		[self updateDatasource];
	} else {
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Invalid Media File URL"
																		message:nil
																 preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"OK"
														   style:UIAlertActionStyleDefault
														 handler:nil];
		
		[alert addAction:okButton];
		
		[self presentViewController:alert animated:YES completion:nil];
	}
}

#pragma mark - UITableViewDelegate/Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _rowsDatasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	__typeof(self) __weak weakSelf = self;
	
    id<FYTableCellItem> item = _rowsDatasource[indexPath.row];
    
    FYTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([item class])];
    
    cell.item = item;
	
	if ([cell isKindOfClass:[FYTextFieldCell class]]) {
		FYTextFieldCell* textFieldCell = (FYTextFieldCell*)cell;
		
		textFieldCell.textAddedCallback = ^(NSString* text) {
			__typeof(weakSelf) __strong strongSelf = weakSelf;
			
			if (strongSelf) {
				[strongSelf addMediaFileWithUrl:[NSURL URLWithString:text]];
			}
		};
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<FYTableCellItem> item = _rowsDatasource[indexPath.row];
	
    if ([item isKindOfClass:[FYMediaItem class]]) {
        FYPlaybackViewController* playbackViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"FYPlaybackViewController"];
		
		playbackViewController.mediaItem = (FYMediaItem*)item;
		
		[self.navigationController pushViewController:playbackViewController animated:YES];
    }    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
