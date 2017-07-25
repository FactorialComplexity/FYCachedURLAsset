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

#import <Foundation/Foundation.h>

#if CACHED_URL_ASSET_DEBUG_LOG || CACHED_URL_ASSET_VERBOSE_LOG
#	define FYLogD(fmt, ...) NSLog((@"(FYCachedURLAsset) D " fmt), ##__VA_ARGS__)
#else
#   define FYLogD(...)
#endif

#if CACHED_URL_ASSET_VERBOSE_LOG
#	define FYLogV(fmt, ...) NSLog((@"(FYCachedURLAsset) V " fmt), ##__VA_ARGS__)
#else
#	define FYLogV(fmt, ...)
#endif

#define FYLogI(fmt, ...) NSLog((@"(FYCachedURLAsset) I " fmt), ##__VA_ARGS__)
#define FYLogE(fmt, ...) NSLog((@"(FYCachedURLAsset) E " fmt), ##__VA_ARGS__)
