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

#import <UIKit/UIKit.h>

#import "Moodstocks.h"

@protocol MSScannerControllerDelegate;

#if !TARGET_IPHONE_SIMULATOR
#define MS_HAS_AVFF 1
#endif

#if MS_HAS_AVFF
#import <AVFoundation/AVFoundation.h>
#endif

@interface MSScannerController : UIViewController<
MSRequestDelegate
#if MS_HAS_AVFF
, AVCaptureVideoDataOutputSampleBufferDelegate
#endif
>{
    // Scanning UI
    UIView*      _videoPreviewView;
    UIImageView* _stillImageView;
    
#if MS_HAS_AVFF
    // Scanning capture logic
    AVCaptureSession*           captureSession;
    AVCaptureVideoPreviewLayer* previewLayer;
    AVCaptureVideoOrientation   orientation;
#endif
    
    // Scanning toolbar
    UIBarButtonItem* _dismissButton;
    UIBarButtonItem* _captureButton;
    UIToolbar* _toolbar;
    
    ASIHTTPRequest* _loadingRequest;
    
    id<MSScannerControllerDelegate> _delegate;
}

@property (nonatomic, retain) UIView *videoPreviewView;
@property (nonatomic, retain) UIImageView* stillImageView;
#if MS_HAS_AVFF
@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) AVCaptureVideoOrientation orientation;
#endif
@property (nonatomic, assign) BOOL oldDevice;
@property (nonatomic, assign) id<MSScannerControllerDelegate> delegate;

@end

@protocol MSScannerControllerDelegate<NSObject>
@required
- (void)scannerController:(MSScannerController*)scanner didFinishScanningWithInfo:(NSDictionary *)info;
- (void)scannerControllerDidCancel:(MSScannerController*)scanner;
@end
