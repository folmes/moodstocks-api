/**
 * Copyright (c) 2011 Moodstocks SAS
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

#if !TARGET_IPHONE_SIMULATOR
#import <AVFoundation/AVFoundation.h>
#endif

// Returns YES if the hardware we're running on is too old to support `vm_copy'
BOOL MSShouldSkipVMCopy(void);

#if !TARGET_IPHONE_SIMULATOR
// Creates a CoreGraphics image from a camera frame buffer
CGImageRef MSCreateImageFromSampleBuffer(CMSampleBufferRef sbuf, int copy, int skip_alpha);

// Create a new re-oriented image (see EXIF orientations for more details)
CGImageRef MSCreateImageFromFrameAndOrientation(CGImageRef frame, AVCaptureVideoOrientation orientation, CGFloat minDim, CGFloat maxDim);
#endif
