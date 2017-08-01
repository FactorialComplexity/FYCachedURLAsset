FYCachedURLAsset
============

[![Version](https://img.shields.io/cocoapods/v/FYCachedURLAsset.svg?style=flat)](http://cocoapods.org/pods/FYCachedURLAsset)
[![License](https://img.shields.io/cocoapods/l/FYCachedURLAsset.svg?style=flat)](http://cocoapods.org/pods/FYCachedURLAsset)
[![Platform](https://img.shields.io/cocoapods/p/FYCachedURLAsset.svg?style=flat)](http://cocoapods.org/pods/FYCachedURLAsset)

It's enhanced `AVURLAsset` with seamless cache layer. It handles the playing of an audio/video file while streaming and simultaneuosly saving downloaded data to a local URL. <i>FYCachedURLAsset</i> was designed to prevent download the same bytes twice. 

## Example

![screenshot](https://raw.githubusercontent.com/factorialcomplexity/master/FYCachedURLAsset/Screenshots/media.png)
![screenshot](https://raw.githubusercontent.com/factorialcomplexity/master/FYCachedURLAsset/Screenshots/player.png)

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

<b>Manual:</b>
<br>
Add to your project source files from `FYCachedURLAsset/Classes` folder
<br>
<br>
<b>CocoaPods:</b>
<br>
<i>FYCachedURLAsset</i> is available through [CocoaPods](http://cocoapods.org). To install
it, add the following line to your Podfile:
<pre>
pod 'FYCachedURLAsset'
</pre>

## How to use

<i>FYCachedURLAsset</i> is a replacement for `[AVURLAsset URLAssetWithURL:URL options:nil]`, but with additional local file path argument
```objective-c
NSString *cacheFilePath = [documentsPath stringByAppendingPathComponent:[URL lastPathComponent]];

FYCachedURLAsset *asset = [FYCachedURLAsset cachedURLAssetWithURL:URL cacheFilePath:cacheFilePath];
```

## Features

* supports streaming of media file, so it can be playbacked as soon as first data is available
* simultaneously saves all downloaded data to a file during streaming
* gracefully handles interruptions and resumes download only from place where was stopped
* supports ETag header attribute to skip file download if no changes were made on the remote file from the last time
* allows to seek stream to any place, but with limited cache support

## License

<i>FYCachedURLAsset</i> is available under the MIT license. See the LICENSE file for more info.
