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

// Controllers
#import "FYHomeViewController.h"

// Model
#import "FYCachedURLAsset.h"
#import "FYContentProvider.h"

// Views
#import "FYProgressView.h"

// Cells
#import "FYMediaCell.h"

@interface FYHomeViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>
@end

@implementation FYHomeViewController {
	NSArray *_testDatasource;
	
	__weak IBOutlet UILabel *_timeLabel;
	__weak IBOutlet UISlider *_timeSlider;
	__weak IBOutlet UIView *_videoPlayerLayerView;
	__weak IBOutlet FYProgressView *_progressView;
    __weak IBOutlet UITableView *_tableView;
	
	AVPlayer *_player;
	NSTimer* _timer;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

	[self setupDatasource];
    
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 40;
	
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
}

#pragma mark - Callbacks

- (void)updateProgress
{
	FYCachedURLAsset* asset = (FYCachedURLAsset*)_player.currentItem.asset;
	[_progressView updateWithCacheInfo:asset.cacheInfo];
}

- (IBAction)timeSliderValueChanged:(UISlider *)sender {

	FYCachedURLAsset *asset = (FYCachedURLAsset *)_player.currentItem.asset;
	
	if ([asset statusOfValueForKey:@"duration" error:nil] == AVKeyValueStatusLoaded) {
		
		CMTime time = CMTimeMake(sender.value * (float)asset.duration.value / asset.duration.timescale, 1);
		
		[_player pause];
		
		[_player seekToTime:time completionHandler:^(BOOL finished) {
			if (finished) {				
				int32_t seconds = time.value % 60;
				int32_t minutes = (int32_t)time.value / 60;
				
				_timeLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
				
				[_player play];
			}
		}];
	}
}

- (IBAction)backwardClicked:(id)sender {
	FYCachedURLAsset *asset = (FYCachedURLAsset *)_player.currentItem.asset;
	
	if ([asset statusOfValueForKey:@"duration" error:nil] == AVKeyValueStatusLoaded) {
		
		CMTime time = CMTimeMake(_timeSlider.value * (float)asset.duration.value / asset.duration.timescale - 10, 1);
		
		[_player pause];
		[_player seekToTime:time completionHandler:^(BOOL finished) {
			if (finished) {
				int32_t seconds = time.value % 60;
				int32_t minutes = (int32_t)time.value / 60;
				
				_timeLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
				
				[_player play];
			}
		}];
	}
}

- (IBAction)forwardClicked:(id)sender {
	FYCachedURLAsset *asset = (FYCachedURLAsset *)_player.currentItem.asset;
	
	if ([asset statusOfValueForKey:@"duration" error:nil] == AVKeyValueStatusLoaded) {
		
		CMTime time = CMTimeMake(_timeSlider.value * (float)asset.duration.value / asset.duration.timescale + 10, 1);
		
		[_player pause];
		[_player seekToTime:time completionHandler:^(BOOL finished) {			
			if (finished) {
				int32_t seconds = time.value % 60;
				int32_t minutes = (int32_t)time.value / 60;
				
				_timeLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
				
				[_player play];
			}
		}];
	}
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"rate"]) {
		NSLog(@"Rate changed to : %@", change);
	} else if ([keyPath isEqualToString:@"status"]) {
		NSInteger newStatus = [change[NSKeyValueChangeNewKey] integerValue];
		
		NSLog(@"Player state is: %@", @[@"Unknown", @"Ready to Play", @"Failed"][newStatus]);
	} else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
		
	} else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
		if (_player.currentItem.playbackLikelyToKeepUp) {
			[_player play];
		}
	} else if ([keyPath isEqualToString:@"currentItem"]) {
		AVPlayerItem *item = change[NSKeyValueChangeOldKey];
		
		[item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
		
		AVPlayerItem *newItem = change[NSKeyValueChangeNewKey];
		
		[newItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:NULL];
	}
}

#pragma mark - Private

- (void)setupDatasource {
	_testDatasource = @[
						@{@"name" : @"Audio MP3", @"url" : @"https://github.com/fycachedurlasset/raw/master/Example/Data/audio.mp3"},
						@{@"name" : @"Video", @"url" : @"https://gitlab.f17y.com/ios/fycachedurlasset/raw/master/Example/Data/video.mp4"}];
}

#pragma mark - UITableViewDelegate/Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _testDatasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	FYMediaCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FYMediaCell"];
	NSDictionary *meta = _testDatasource[indexPath.row];
	
	cell.mediaName = meta[@"name"];
	cell.mediaURL = meta[@"url"];
	
	NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																   NSUserDomainMask,
																   YES) firstObject];
	NSString *cacheFileName = [NSString stringWithFormat:@"test%d.%@", (int32_t)indexPath.row, [meta[@"url"] pathExtension]];
	NSString *cacheFilePath = [documentsPath stringByAppendingPathComponent:cacheFileName];

	cell.isCached = [[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath];
	
	return cell;
}

- (void)onResourceForURLChanged:(NSNotification*)note
{
	if (note.object == _player.currentItem.asset)
	{
		// restart player
		[self resetPlayerWithURL:((FYCachedURLAsset*)_player.currentItem.asset).originalURL];
	}
}

- (void)resetPlayerWithURL:(NSURL*)URL
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:FYResourceForURLChangedNotification object:nil];

	NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																   NSUserDomainMask,
																   YES) firstObject];
	
	NSString *cacheFileName = [URL lastPathComponent];
	NSString *cacheFilePath = [documentsPath stringByAppendingPathComponent:cacheFileName];
	
	FYCachedURLAsset *asset = [FYCachedURLAsset cachedURLAssetWithURL:URL cacheFilePath:cacheFilePath];
	AVPlayerItem *newItem = [[AVPlayerItem alloc] initWithAsset:asset];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onResourceForURLChanged:)
		name:FYResourceForURLChangedNotification object:asset];
	
	if (_player.currentItem) {
		[_player replaceCurrentItemWithPlayerItem:newItem];
		[_player play];
	} else {
		_player = [AVPlayer playerWithPlayerItem:newItem];
		[newItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:NULL];
		[_player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
		[_player play];
		
		AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_player];
		layer.anchorPoint = CGPointZero;
		[_videoPlayerLayerView.layer addSublayer:layer];
		layer.bounds = _videoPlayerLayerView.layer.bounds;
		
		__typeof(AVPlayer *) __weak weakPlayer = _player;
		__typeof(UISlider *) __weak weakSlider = _timeSlider;
		__typeof(UILabel *) __weak weakLabel = _timeLabel;
		
		[_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 15) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
			FYCachedURLAsset *asset = (FYCachedURLAsset *)weakPlayer.currentItem.asset;

			if ([asset statusOfValueForKey:@"duration" error:nil] == AVKeyValueStatusLoaded) {
				weakSlider.value = (float)CMTimeGetSeconds(time) / CMTimeGetSeconds(asset.duration);
				
				int32_t seconds = (int32_t)CMTimeGetSeconds(time) % 60;
				int32_t minutes = CMTimeGetSeconds(time) / 60;
				
				weakLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
			}
		}];
	}

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *meta = _testDatasource[indexPath.row];
	[self resetPlayerWithURL:[NSURL URLWithString:meta[@"url"]]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
