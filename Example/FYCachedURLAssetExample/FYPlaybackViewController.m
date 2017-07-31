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

#import "FYPlaybackViewController.h"

// Categories
#import "FYPlaybackViewController+NavigationBar.h"

@implementation FYPlaybackViewController {
	__weak IBOutlet UIWebView *_audioAnimationWebView;
	__weak IBOutlet UIView *_playerView;
	AVPlayerLayer *_playerLayer;
	__weak IBOutlet UIButton *_skipBackwardButton;
	__weak IBOutlet UISlider *_timeSlider;
	__weak IBOutlet UIView *_timeSlidedTrackView;
	__weak IBOutlet NSLayoutConstraint *_progressViewWidthConstraint;
	__weak IBOutlet UIButton *_skipForwardButton;
	__weak IBOutlet UILabel *_timeLabel;
	__weak IBOutlet UIButton *_playPauseButton;
	
	AVPlayer *_player;
	NSTimer* _timer;
	
	BOOL _isPlaying;
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	_timeLabel.text = @"";
	self.title = _mediaItem.mediaName;
	
	[self navigationBarStyleForPlayback];
	
	[_timeSlider setThumbImage:[UIImage imageNamed:@"slider_thumb_icon"] forState:UIControlStateNormal];
	[_timeSlider setThumbImage:[UIImage imageNamed:@"slider_thumb_icon"] forState:UIControlStateHighlighted];
	[_timeSlider setMinimumTrackImage:[UIImage alloc] forState:UIControlStateNormal];
	[_timeSlider setMaximumTrackImage:[UIImage alloc] forState:UIControlStateNormal];
	
	[self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
	
	_isPlaying = YES;
	
	[self resetPlayerWithURL:[NSURL URLWithString:_mediaItem.mediaURL]];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	FYCachedURLAsset *asset = (FYCachedURLAsset *)_player.currentItem.asset;
	[asset cancel];
	
	[_player pause];
	[_player replaceCurrentItemWithPlayerItem:nil];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	
	_playerLayer.frame = _playerView.layer.bounds;
}

#pragma mark - Callbacks

- (IBAction)playPauseClicked:(id)sender {
	_isPlaying = !_isPlaying;
	
	if (_isPlaying) {
		[_playPauseButton setImage:[UIImage imageNamed:@"pause_icon"] forState:UIControlStateNormal];
		
		[_player play];
		
		[UIView animateWithDuration:0.4 animations:^ {
			_audioAnimationWebView.layer.opacity = 1;
		}];
	} else {
		[_playPauseButton setImage:[UIImage imageNamed:@"play_icon"] forState:UIControlStateNormal];
		
		[_player pause];
		
		[UIView animateWithDuration:0.2 animations:^ {
			_audioAnimationWebView.layer.opacity = 0;
		}];
	}
}

- (void)updateProgress {
	FYCachedURLAsset* asset = (FYCachedURLAsset*)_player.currentItem.asset;
	
	if (asset.cacheInfo.availableData) {
		_progressViewWidthConstraint.constant = 1.0 * asset.cacheInfo.availableDataOnDisk / asset.cacheInfo.contentLength * _timeSlidedTrackView.frame.size.width;
	} else {
		_progressViewWidthConstraint.constant = 0;
	}
}

- (IBAction)timeSliderValueChanged:(UISlider *)sender {
	FYCachedURLAsset *asset = (FYCachedURLAsset *)_player.currentItem.asset;
	
	if ([asset statusOfValueForKey:@"duration" error:nil] == AVKeyValueStatusLoaded) {
		CMTime time = CMTimeMake(sender.value * (float)asset.duration.value / asset.duration.timescale, 1);
		
		[self seekToTime:time];
	}
}

- (IBAction)backwardClicked:(id)sender {
	FYCachedURLAsset *asset = (FYCachedURLAsset *)_player.currentItem.asset;
	
	if ([asset statusOfValueForKey:@"duration" error:nil] == AVKeyValueStatusLoaded) {
		CMTime time = CMTimeMake(_timeSlider.value * (float)asset.duration.value / asset.duration.timescale - 10, 1);
		
		[self seekToTime:time];
	}
}

- (IBAction)forwardClicked:(id)sender {
	FYCachedURLAsset *asset = (FYCachedURLAsset *)_player.currentItem.asset;
	
	if ([asset statusOfValueForKey:@"duration" error:nil] == AVKeyValueStatusLoaded) {
		CMTime time = CMTimeMake(_timeSlider.value * (float)asset.duration.value / asset.duration.timescale + 10, 1);
		
		[self seekToTime:time];
	}
}

- (void)onResourceForURLChanged:(NSNotification*)note {
	if (note.object == _player.currentItem.asset) {
		// restart player
		[self resetPlayerWithURL:((FYCachedURLAsset*)_player.currentItem.asset).originalURL];
	}
}

-(void)itemDidFinishPlaying:(NSNotification *) notification {
	[self.navigationController popViewControllerAnimated:YES];
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

- (void)seekToTime:(CMTime)time {
	[_player pause];
	[_player seekToTime:time completionHandler:^(BOOL finished) {
		if (finished) {
			[self updateTimeLabelWithTime:time duration:_player.currentItem.asset.duration];
			
			if (_isPlaying) {
				[_player play];
			}
		}
	}];
}

- (void)updateTimeLabelWithTime:(CMTime)time duration:(CMTime)duration {
	int32_t seconds = (time.value / time.timescale) % 60;
	int32_t minutes = (int32_t)(time.value / time.timescale) / 60;
	
	int32_t totalSeconds = (duration.value / duration.timescale) % 60;
	int32_t totalMinutes = (int32_t)(duration.value / duration.timescale) / 60;
	
	_timeLabel.text = [NSString stringWithFormat:@"%02d:%02d / %02d:%02d", minutes, seconds, totalMinutes, totalSeconds];
}

- (void)resetPlayerWithURL:(NSURL*)URL {
	__typeof(self) __weak weakSelf = self;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:FYResourceForURLChangedNotification object:nil];
	
	NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																   NSUserDomainMask,
																   YES) firstObject];
	
	NSString *cacheFileName = [URL lastPathComponent];
	NSString *cacheFilePath = [documentsPath stringByAppendingPathComponent:cacheFileName];
	
	FYCachedURLAsset *asset = [FYCachedURLAsset cachedURLAssetWithURL:URL cacheFilePath:cacheFilePath];
	AVPlayerItem *newItem = [[AVPlayerItem alloc] initWithAsset:asset];
	
	[asset loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:^() {
		__typeof(weakSelf) __strong strongSelf = weakSelf;
		
		if (strongSelf) {
			if ([[asset.tracks firstObject].mediaType isEqualToString:@"soun"]) {
				[strongSelf createAudioAnimation];
			}
			
			!strongSelf->_mediaPropertiesCallback ?: strongSelf->_mediaPropertiesCallback(asset.cacheInfo.contentLength, (int32_t) (asset.duration.value / asset.duration.timescale));
		}
	}];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onResourceForURLChanged:)
												 name:FYResourceForURLChangedNotification object:asset];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:newItem];
	
	
	if (_player.currentItem) {
		[_player replaceCurrentItemWithPlayerItem:newItem];
		[_player play];
	} else {
		_player = [AVPlayer playerWithPlayerItem:newItem];
		[newItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:NULL];
		[_player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
		[_player play];
		
		_playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
		[_playerView.layer addSublayer:_playerLayer];
		_playerLayer.frame = _playerView.layer.bounds;
		
		__typeof(self) __weak weakSelf = self;
		
		[_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 15) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
			if ([asset statusOfValueForKey:@"duration" error:nil] == AVKeyValueStatusLoaded) {
				__typeof(weakSelf) __strong strongSelf = weakSelf;
				
				if (strongSelf) {
					strongSelf->_timeSlider.value = (float)CMTimeGetSeconds(time) / CMTimeGetSeconds(strongSelf->_player.currentItem.asset.duration);
					
					[strongSelf updateTimeLabelWithTime:time duration:asset.duration];
				}
			}
		}];
	}
}

- (void)createAudioAnimation {
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"audio_animation" ofType:@"gif"];
	NSURL *requestURL = [NSURL fileURLWithPath:filePath];
	[_audioAnimationWebView loadRequest:[NSMutableURLRequest requestWithURL:requestURL]];
}

@end
