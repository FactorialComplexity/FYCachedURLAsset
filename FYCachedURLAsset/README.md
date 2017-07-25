FYCachedURLAsset
============

[![CI Status](http://img.shields.io/travis/FactorialComplexity/FYCachedURLAsset.svg?style=flat)](https://travis-ci.org/FactorialComplexity/FYCachedURLAsset)
[![Version](https://img.shields.io/cocoapods/v/FYCachedURLAsset.svg?style=flat)](http://cocoapods.org/pods/FYCachedURLAsset)
[![License](https://img.shields.io/cocoapods/l/FYCachedURLAsset.svg?style=flat)](http://cocoapods.org/pods/FYCachedURLAsset)
[![Platform](https://img.shields.io/cocoapods/p/FYCachedURLAsset.svg?style=flat)](http://cocoapods.org/pods/FYCachedURLAsset)

It's enhanced `AVURLAsset` with seamless cache layer. It handles the playing of an audio/video file while streaming and simultaneuosly saving downloaded data to a local URL. <i>FYCachedURLAsset</i> was designed to prevent download the same bytes twice. 

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

<b>Manual:</b><br>
Add to your project the next source files: <br>
<pre>
AVAssetResourceLoadingDataRequest+Info.h
AVAssetResourceLoadingDataRequest+Info.m
FYCachedURLAsset.h
FYCachedURLAsset.m
FYCachedURLAssetLog.h
FYContentProvider.h
FYContentProvider.m
FYHEADRequest.h
FYHEADRequest.m
FYRandomAccessContentLoader.h
FYRandomAccessContentLoader.m
FYSerialContentLoader.h
FYSerialContentLoader.m
NSHTTPURLResponse+Headers.h
NSHTTPURLResponse+Headers.m
</pre>
<br>
<b>CocoaPods:</b><br>
<i>FYCachedURLAsset</i> is available through [CocoaPods](http://cocoapods.org). To install
it, add the following line to your Podfile:
<pre>
pod 'FYCachedURLAsset'
</pre>

## How to use

<i>FYCachedURLAsset</i> is a replacement for `[AVURLAsset URLAssetWithURL:URL options:nil]`, but with additional local file path argument
<pre>
NSString *cacheFilePath = [documentsPath stringByAppendingPathComponent:[URL lastPathComponent]];
FYCachedURLAsset *asset = [FYCachedURLAsset cachedURLAssetWithURL:URL cacheFilePath:cacheFilePath];
</pre>

## License

<i>FYCachedURLAsset</i> is available under the MIT license. See the LICENSE file for more info.
