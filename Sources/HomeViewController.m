//
//  ViewController.m
//  FYCachedUrlAsset
//
//  Created by Yuriy Romanchenko on 4/23/15.
//  Copyright (c) 2015 FactorialComplexity. All rights reserved.
//

// Controllers
#import "HomeViewController.h"

// Model
#import "FYCachedURLAsset.h"
#import "FYContentProvider.h"
#import "FYCachedStorage.h"

// Cells
#import "MediaCell.h"

@interface HomeViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>
@end

@implementation HomeViewController {
	NSArray *_testDatasource;
	
	__weak IBOutlet UILabel *_timeLabel;
	__weak IBOutlet UISlider *_timeSlider;
	__weak IBOutlet UIView *_videoPlayerLayerView;
	
	AVPlayer *_player;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

	[self setupDatasource];
	
	[FYContentProvider shared].progressBlock = ^(NSInteger startOffset, NSInteger downloaded, NSInteger totalBytesToDownload) {
		
	};
}

#pragma mark - Callbacks

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
		
		CMTime time = CMTimeMake(_timeSlider.value * (float)asset.duration.value / asset.duration.timescale - 2, 1);
		
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
		
		CMTime time = CMTimeMake(_timeSlider.value * (float)asset.duration.value / asset.duration.timescale + 20, 1);
		
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
		
	}
}

#pragma mark - Private

- (void)setupDatasource {
	_testDatasource = @[
						@{@"name" : @"East of Eden", @"url" : @"https://cs7-2v4.vk-cdn.net/p6/6262b7c27c22af.mp3?extra=hx3WEcrRVBovttA7iM6x2JTJmG_bnHtxrcY-s1GgMNPYNo3S9d-90y_jFq_Kj9Cd7j0dUcC4p5aGjWQMr48T-vwfPXjb7xY?/Zella%20Day%20-%20East%20of%20Eden.mp3"},
						@{@"name" : @"Spaceman", @"url" : @"https://psv4.vk.me/c521114/u159894783/audios/39b74ba982cb.mp3?extra=haTJfDeJbAPUwzmSc9IvgFezygpXGwE_VKMiV2lRz006rs5hfEr8nSQMU4KA8MT7_nuU3l24WpwCbLdMawH53VFg0T4q-O4?/Hardwell%20@%20Ultra%20Music%20Festival%202013%20-%20Hardwell%20-%20Spaceman%20(Aino%20Rework%20Intro%20Edit)%20%3E%20vk.com/clubmusicit.mp3"},
						@{@"name" : @"Song #2", @"url" : @"https://cs7-1v4.vk-cdn.net/p10/0f0773d66fe87c.mp3?extra=J7WbEf8sjA_O3eke_mrbaqMUVUd2h_OIbKmaDRLMlQ-QdGfYKhAl-3ZFEjaZ-fDN7jWE6D2nBvUSR-usKCtVkvtd4oQrv-c?/The%20Ting%20Tings%20-%20That%27s%20Not%20My%20Name.mp3"},
						@{@"name" : @"Video", @"url" : @"http://hmmb-staging.s3.amazonaws.com/the_world_before_video-768px.mp4"},
						];
}

#pragma mark - UITableViewDelegate/Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _testDatasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MediaCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MediaCell"];
	NSDictionary *meta = _testDatasource[indexPath.row];
	
	cell.mediaName = meta[@"name"];
	cell.mediaURL = meta[@"url"];
	cell.isCached = [[FYCachedStorage shared] cachedFileExistWithName:[cell.mediaURL lastPathComponent]];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *meta = _testDatasource[indexPath.row];
	
	NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																   NSUserDomainMask,
																   YES) firstObject];
	
	NSString *cacheFileName = [NSString stringWithFormat:@"test%d.%@", (int32_t)indexPath.row, [meta[@"url"] pathExtension]];
	NSString *cacheFilePath = [documentsPath stringByAppendingPathComponent:cacheFileName];
	
	FYCachedURLAsset *asset = [FYCachedURLAsset cachedURLAssetWithURL:[NSURL URLWithString:meta[@"url"]] cacheFilePath:cacheFilePath];
	AVPlayerItem *newItem = [[AVPlayerItem alloc] initWithAsset:asset];
	
	if (_player.currentItem) {
		[_player replaceCurrentItemWithPlayerItem:newItem];
		[_player play];
	} else {
		_player = [AVPlayer playerWithPlayerItem:newItem];
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

@end
