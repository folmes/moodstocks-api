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

#import "MSLaserView.h"

#import <QuartzCore/QuartzCore.h>

static const CGFloat kMSLaserViewHeight            = 60.0f; // pixels
static const CGFloat kMSLaserViewAnimationDuration = 1.5f; // seconds


@implementation MSLaserView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _maxHeight = self.frame.size.height;
        
        // Restrict the size to the gradient height to minimize the amount blended areas (i.e. are with transparent content)
        // that are expensive to compute
        self.frame = CGRectMake(self.frame.origin.x,
                                self.frame.origin.y,
                                self.frame.size.width,
                                kMSLaserViewHeight);
    }
    return self;
}

+ (Class)layerClass {
	return [CAGradientLayer class];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    // Introduce a negative offset so that the scanner covers the top part of the view
    self.center = CGPointMake(self.center.x, self.center.y - kMSLaserViewHeight);
    
    CAGradientLayer *gradientLayer = (CAGradientLayer *) self.layer;
    gradientLayer.colors =
    [NSArray arrayWithObjects:
     (id)[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.0].CGColor,
     (id)[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.6].CGColor,
     (id)[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.0].CGColor,
     nil];
    
    gradientLayer.locations  = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],
                                [NSNumber numberWithFloat:0.98],
                                [NSNumber numberWithFloat:1.0], nil];
    
    NSUInteger opts = UIViewAnimationOptionRepeat | UIViewAnimationOptionAllowUserInteraction;
    [UIView animateWithDuration:kMSLaserViewAnimationDuration
                          delay:0
                        options:opts
                     animations:^{
                         self.center = CGPointMake(self.center.x, self.center.y + _maxHeight + kMSLaserViewHeight);
                     }
                     completion:^(BOOL finished){
                         // nothing to do
                     }
     ];
}

@end
