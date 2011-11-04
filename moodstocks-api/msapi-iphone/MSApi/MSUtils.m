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

#import "MSUtils.h"

#include <sys/sysctl.h>

// The function below has been take from MVCNetworking Apple sample code
// This method detects if the hardware is "old" (say iPhone 3G)
// so that to bypass a bug when copying image data from the current
// sample buffer
//
// For more details please refer to:
// http://stackoverflow.com/questions/3367849/cgbitmapcontextcreateimage-vm-copy-failed-iphone-sdk
BOOL MSShouldSkipVMCopy(void) {
    BOOL    result;
    int     err;
    char    value[32];
    size_t  valueLen;
    
    result = NO;
    
    // Note that sysctlbyname will fail if value is too small.  That's fine by 
    // us.  The model numbers we're specifically looking will all fit.  Anything 
    // with a longer name should be more capable, and hence not need a limited size.
    
    valueLen = sizeof(value);
    err = sysctlbyname("hw.machine", value, &valueLen, NULL, 0);
    if (err == 0) {
        result = 
        (strcmp(value, "iPhone1,1") == 0)        // iPhone
        || (strcmp(value, "iPhone1,2") == 0)        // iPhone 3G
        || (strcmp(value, "iPod1,1"  ) == 0)        // iPod touch
        || (strcmp(value, "iPod2,1"  ) == 0)        // iPod touch (second generation)
        || (strcmp(value, "iPod2,2"  ) == 0)        // iPod touch (second generation)
        ;
    }
    return result;
}


#if !TARGET_IPHONE_SIMULATOR
// Adapted from http://developer.apple.com/library/ios/#qa/qa1702/_index.html
CGImageRef MSCreateImageFromSampleBuffer(CMSampleBufferRef sbuf, int copy, int skip_alpha) {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sbuf); 
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // NOTE: we need to copy memory on iPhone 3G to avoid errors with
    //       vm_copy:
    // <Error>: CGDataProviderCreateWithCopyOfData: vm_copy failed: status 2.
    void *baseAddress = NULL;
    if (copy) {
        void *tmp = CVPixelBufferGetBaseAddress(imageBuffer);
        size_t sz = bytesPerRow*height;
        baseAddress = malloc(sz);
        memcpy(baseAddress, tmp, sz);
    }
    else
        baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    
    CGBitmapInfo binfo = kCGBitmapByteOrder32Little;
    if (skip_alpha)
        binfo |= kCGImageAlphaNoneSkipFirst;
    else
        binfo |= kCGImageAlphaPremultipliedFirst; 
    
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, 
                                                 bytesPerRow, colorSpace, binfo); 
    
    CGImageRef quartzImage = CGBitmapContextCreateImage(context); 
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    CGContextRelease(context); 
    CGColorSpaceRelease(colorSpace);
    
    if (copy) {
        free(baseAddress);
        baseAddress = NULL;
    }
    
    return (quartzImage);
}

CGImageRef MSCreateImageFromFrameAndOrientation(CGImageRef frame, AVCaptureVideoOrientation orientation, CGFloat minDim, CGFloat maxDim) {
    CGSize newSize;
    if (orientation == AVCaptureVideoOrientationPortrait || orientation == AVCaptureVideoOrientationPortraitUpsideDown) 
        newSize = CGSizeMake(minDim, maxDim);
    else
        newSize = CGSizeMake(maxDim, minDim);
    
    CGRect newRect        = CGRectMake(0, 0, newSize.width, newSize.height);
    CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    
    BOOL transpose = NO;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    if (orientation == AVCaptureVideoOrientationPortrait) {
        transpose = YES;
        transform = CGAffineTransformTranslate(transform, 0, newSize.height);
        transform = CGAffineTransformRotate(transform, -M_PI_2);
    }
    else if (orientation == AVCaptureVideoOrientationLandscapeLeft) {
        transpose = NO;
        transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
        transform = CGAffineTransformRotate(transform, M_PI);
    }
    else if (orientation == AVCaptureVideoOrientationLandscapeRight) {
        transpose = NO;
    }
    else if (orientation == AVCaptureVideoOrientationPortraitUpsideDown) {
        transpose = YES;
        transform = CGAffineTransformTranslate(transform, newSize.width, 0);
        transform = CGAffineTransformRotate(transform, M_PI_2);
    }
    
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                CGImageGetBitsPerComponent(frame),
                                                0,
                                                CGImageGetColorSpace(frame),
                                                CGImageGetBitmapInfo(frame));
    
    CGContextConcatCTM(bitmap, transform);
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
    CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, frame);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    
    CGContextRelease(bitmap);
    
    return (newImageRef);
}
#endif
