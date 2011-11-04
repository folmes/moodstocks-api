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

#import "MSScannerController.h"

#import "MSLaserView.h"

#import "MSUtils.h"

#import <CoreVideo/CoreVideo.h> /* for kCVPixelBufferPixelFormatTypeKey */

@interface MSScannerController ()

#if MS_HAS_AVFF
- (void)deviceOrientationDidChange;
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position;
- (AVCaptureDevice *)backFacingCamera;
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
#endif

- (void)startCapture;
- (void)stopCapture;

- (void)dismissAction;
- (void)captureAction;
- (void)cancelAction;
- (void)scan:(UIImage*)query;

@end

/**
 * PLEASE MAKE SURE TO REPLACE WITH YOUR KEY/SECRET PAIR
 *
 * For more details, please refer to:
 * https://github.com/Moodstocks/moodstocks-api/wiki/api-v2-doc
 */
static NSString* kMSAPIKey    = @"ApIkEy";
static NSString* kMSAPISecret = @"SeCrEt";

// Standard toolbar height is 44 pixels: we use 54 pixels here in combination
// with a full screen layout so that the video preview is as close as possible
// of the 4:3 aspect ratio, i.e. width = 320 pixels, height = 426 pixels
static const CGFloat kMSScannerToolbarHeight = 54.0f; // pixels

// This is to make sure the capture button is centered (work around)
static CGFloat kMSScannerRightFixedSpace = 140; // pixels

// Image encoding specifications
static CGFloat kMSScannerImageMinDim  = 360.0;
static CGFloat kMSScannerImageMaxDim  = 480.0;

@implementation MSScannerController

@synthesize videoPreviewView = _videoPreviewView;
@synthesize stillImageView   = _stillImageView;
#if MS_HAS_AVFF
@synthesize captureSession;
@synthesize previewLayer;
@synthesize orientation;
#endif
@synthesize oldDevice;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.wantsFullScreenLayout = YES;
        self.hidesBottomBarWhenPushed = YES;
        self.oldDevice = MSShouldSkipVMCopy();
    }
    return self;
}

- (void)dealloc {
    [self stopCapture];
    
    [_loadingRequest cancel];
    [_loadingRequest release]; _loadingRequest = nil;
    
    _delegate = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Private

#if MS_HAS_AVFF
- (void)deviceOrientationDidChange {	
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
	if (deviceOrientation == UIDeviceOrientationPortrait)
		self.orientation = AVCaptureVideoOrientationPortrait;
	else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
		self.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
	
	// AVCapture and UIDevice have opposite meanings for landscape left and right (AVCapture orientation is the same as UIInterfaceOrientation)
	else if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
		self.orientation = AVCaptureVideoOrientationLandscapeRight;
	else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
		self.orientation = AVCaptureVideoOrientationLandscapeLeft;
	
	// Ignore device orientations for which there is no corresponding still image orientation (e.g. UIDeviceOrientationFaceUp)
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    
    return nil;
}

- (AVCaptureDevice *)backFacingCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections {
    for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return connection;
			}
		}
	}
    
	return nil;
}
#endif

- (void)startCapture {
#if MS_HAS_AVFF
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    self.orientation = AVCaptureVideoOrientationPortrait;
    
    // Set torch and flash mode to auto
	if ([[self backFacingCamera] hasFlash]) {
		if ([[self backFacingCamera] lockForConfiguration:nil]) {
			if ([[self backFacingCamera] isFlashModeSupported:AVCaptureFlashModeAuto])
                [[self backFacingCamera] setFlashMode:AVCaptureFlashModeAuto];
			[[self backFacingCamera] unlockForConfiguration];
		}
	}
    
	if ([[self backFacingCamera] hasTorch]) {
		if ([[self backFacingCamera] lockForConfiguration:nil]) {
			if ([[self backFacingCamera] isTorchModeSupported:AVCaptureTorchModeAuto])
                [[self backFacingCamera] setTorchMode:AVCaptureTorchModeAuto];
			[[self backFacingCamera] unlockForConfiguration];
		}
	}
    
    // == CAPTURE SESSION SETUP
    AVCaptureDeviceInput* newVideoInput            = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:nil];
    AVCaptureStillImageOutput* newStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings                   = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                                                 forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [newStillImageOutput setOutputSettings:outputSettings];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession release];
    
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480])
        [self.captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    else
        [self.captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    
    if ([self.captureSession canAddInput:newVideoInput])
        [self.captureSession addInput:newVideoInput];
    
    if ([self.captureSession canAddOutput:newStillImageOutput])
        [self.captureSession addOutput:newStillImageOutput];
    
    [newVideoInput release];
    [newStillImageOutput release];
    
    // == VIDEO PREVIEW SETUP
    if (!self.previewLayer)
        self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    
    CALayer* viewLayer = [_videoPreviewView layer];
    [viewLayer setMasksToBounds:YES];
    
    [self.previewLayer setFrame:[_videoPreviewView bounds]];
    if ([self.previewLayer isOrientationSupported])
        [self.previewLayer setOrientation:AVCaptureVideoOrientationPortrait];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [viewLayer insertSublayer:self.previewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
    
    [self.captureSession startRunning];
#endif
}

- (void)stopCapture {
#if MS_HAS_AVFF
    [captureSession stopRunning];
    
    AVCaptureInput* input = [captureSession.inputs objectAtIndex:0];
    [captureSession removeInput:input];
    
    AVCaptureStillImageOutput* output = (AVCaptureStillImageOutput*) [captureSession.outputs objectAtIndex:0];
    [captureSession removeOutput:output];
    
    [self.previewLayer removeFromSuperlayer];
    
    self.previewLayer = nil;
    self.captureSession = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
#endif
}

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self startCapture];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self stopCapture];
}

- (void)loadView {
    [super loadView];
    
    _videoPreviewView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - kMSScannerToolbarHeight)];
    _videoPreviewView.backgroundColor = [UIColor blackColor];
    _videoPreviewView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _videoPreviewView.autoresizesSubviews = YES;
    [self.view addSubview:_videoPreviewView];
    
    _stillImageView = [[UIImageView alloc] initWithFrame:[_videoPreviewView bounds]];
    _stillImageView.backgroundColor = [UIColor clearColor];
    [_videoPreviewView addSubview:_stillImageView];
    
    _dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissAction)];
    _captureButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(captureAction)];
    
    UIBarButtonItem* space  = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    UIBarButtonItem* fspace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
    fspace.width = kMSScannerRightFixedSpace;
    
    _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - kMSScannerToolbarHeight, self.view.frame.size.width, kMSScannerToolbarHeight)];
    _toolbar.barStyle = UIBarStyleBlack;
    _toolbar.tintColor = nil;
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    _toolbar.items = [NSArray arrayWithObjects:_dismissButton, space, _captureButton, fspace, nil];
    [self.view addSubview:_toolbar];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [_toolbar release];          _toolbar = nil;
    [_dismissButton release];    _dismissButton = nil;
    [_captureButton release];    _captureButton = nil;
    [_videoPreviewView release]; _videoPreviewView = nil;
    [_stillImageView release];   _stillImageView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (void)dismissAction {
    if ([_delegate respondsToSelector:@selector(scannerControllerDidCancel:)])
        [_delegate scannerControllerDidCancel:self];
}

- (void)captureAction {
#if MS_HAS_AVFF
    // == CORE CAPTURE LOGIC
    AVCaptureStillImageOutput* output = (AVCaptureStillImageOutput*) [captureSession.outputs objectAtIndex:0];
    AVCaptureConnection *stillImageConnection = [[self class] connectionWithMediaType:AVMediaTypeVideo fromConnections:[output connections]];
    
    if ([stillImageConnection isVideoOrientationSupported])
        [stillImageConnection setVideoOrientation:self.orientation];
    
    void (^imageCaptureHandler)(CMSampleBufferRef imageDataSampleBuffer, NSError *error) = ^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        UIImage *preview = nil;
        UIImage *query = nil;
        if (imageDataSampleBuffer != NULL) {
            CGImageRef imageRef = MSCreateImageFromSampleBuffer(imageDataSampleBuffer, /* copy */ oldDevice ? 1 : 0, /* skip_alpha */ oldDevice ? 1 : 0);
            
            // == PREVIEW IMAGE
            preview = [[UIImage alloc] initWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationRight];
            
            if (preview) {
                [_stillImageView setImage:preview];
                [_stillImageView setAlpha:1.0f];
                
                UIBarButtonItem* cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)] autorelease];
                [_toolbar setItems:[NSArray arrayWithObject:cancelButton] animated:NO];
                
                MSLaserView *laserView = [[MSLaserView alloc] initWithFrame:_videoPreviewView.bounds];
                [_stillImageView addSubview:laserView];
                [laserView release];
            }
            
            // == QUERY IMAGE
            CGImageRef newImageRef = MSCreateImageFromFrameAndOrientation(imageRef, self.orientation, kMSScannerImageMinDim, kMSScannerImageMaxDim);
            query = [UIImage imageWithCGImage:newImageRef];
            
            CGImageRelease(newImageRef);
            CGImageRelease(imageRef);
        }
        
        [self scan:query];
        
        [preview release];
    }; // end of async capture still image handler
    
    [output captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:imageCaptureHandler];
    
    // == UI LOGIC
    // Flash the screen white and fade it out to give UI feedback that a still image was taken
    UIView* flashView = [[UIView alloc] initWithFrame:[_videoPreviewView frame]];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [[[self view] window] addSubview:flashView];
    
    [UIView animateWithDuration:.4f
                     animations:^{
                         [flashView setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         [flashView removeFromSuperview];
                         [flashView release];
                     }
     ];
#endif
}

- (void)cancelAction {
    [_loadingRequest cancel];
    
    // Rollback to the default scanning UI
    UIBarButtonItem* space  = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    UIBarButtonItem* fspace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
    fspace.width = kMSScannerRightFixedSpace;
    
    [_toolbar setItems:[NSArray arrayWithObjects:_dismissButton, space, _captureButton, fspace, nil] animated:YES];
    
    [UIView animateWithDuration:.4f
                     animations:^{
                         [_stillImageView setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         _stillImageView.image = nil;
                         UIView *laserView = nil;
                         for (UIView *v in [_stillImageView subviews]) {
                             if ([v isKindOfClass:[MSLaserView class]])
                                 laserView = v;
                         }
                         
                         [laserView removeFromSuperview];
                     }
     ];
}

#pragma mark - Scanning

- (void)scan:(UIImage*)query {
    Moodstocks *client = [[Moodstocks alloc] initWithKey:kMSAPIKey secret:kMSAPISecret];
    [client search:query delegate:self];
    [client release];
}

#pragma mark - HTTP Querying

- (void)requestLoading:(ASIHTTPRequest *)request {
    [_loadingRequest release];
    _loadingRequest = [request retain];
}

- (void)request:(ASIHTTPRequest *)request didLoad:(id)result {
    [_loadingRequest release]; _loadingRequest = nil;
    
    if ([_delegate respondsToSelector:@selector(scannerController:didFinishScanningWithInfo:)])
        [_delegate scannerController:self didFinishScanningWithInfo:result];
}

- (void)request:(ASIHTTPRequest *)request didFailWithError:(NSError *)error {
    [_loadingRequest release]; _loadingRequest = nil;
    
    // NOTE: define a *real* error message here (e.g. No connection, etc)
    NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:@"Sorry, an error occurred.", @"error", nil];
    
    if ([_delegate respondsToSelector:@selector(scannerController:didFinishScanningWithInfo:)])
        [_delegate scannerController:self didFinishScanningWithInfo:result];
    
    [result release];
}

- (void)didCancelRequest:(ASIHTTPRequest *)request {
    [_loadingRequest release]; _loadingRequest = nil;
}


@end
