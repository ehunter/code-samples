/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "WebImageView.h"
#import "CGRectUtils.h"
#import <QuartzCore/QuartzCore.h>

#define STATIC_BACKGROUND_ALPHA 0
#define PULSE_BACKGROUND_ALPHA .3

@interface WebImageView () <WebImageManagerDelegate>
{
    UIView *background;
    UIImageView *imageView;
    BOOL isImageLoaded;
    NSDate *lastBlankDate;
}

@property (copy) NSURL *currentURL;
@property (assign) WebImageManagerSize size;

@end

@implementation WebImageView

- (id)initWithSize:(WebImageManagerSize)size
{
    if ((self = [super init])) {
        _size = size;
        background = [[UIView alloc] initWithFrame:CGRectZero];
        [background setBackgroundColor:[UIColor blackColor]];
        [background setAlpha:STATIC_BACKGROUND_ALPHA];
        [self addSubview:background];

        imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [imageView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:imageView];

        isImageLoaded = NO;
    }
    return self;
}

- (id)init
{
    return [self initWithSize:WebImageManagerSizeFull];
}

- (void)dealloc
{
    [_currentURL release];
    [lastBlankDate release];
    [imageView release];
    [background release];

    [super dealloc];
}

- (UIImage*)image
{
    return [imageView image];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [imageView setContentMode:contentMode];

    [super setContentMode:contentMode];
}

- (void)setClipsToBounds:(BOOL)clipsToBounds
{
    [imageView setClipsToBounds:clipsToBounds];

    [super setClipsToBounds:clipsToBounds];
}

- (void)setImageWithURL:(NSURL *)url
{
    [self setImageWithURL:url priority:NSOperationQueuePriorityNormal];
}

- (void)setImageWithURL:(NSURL *)url priority:(NSOperationQueuePriority)priority
{
    NSString *oldUrl = [_currentURL absoluteString];
    [self setCurrentURL:url];

    if (_currentURL) {
        if (![oldUrl isEqualToString:[_currentURL absoluteString]]) {
            [self cancelCurrentImageLoad];
            [imageView setAlpha:0];
            [self startPulseAnimation];
            [[App webImageManager] downloadWithURL:_currentURL size:_size delegate:self];
        } else {
            if (isImageLoaded && [[background layer] animationKeys]) {
                [self stopPulseAnimation];
            }
            [_delegate webImageViewDidLoad:self];
        }
    } else {
        if (oldUrl) {
            [lastBlankDate release];
            lastBlankDate = [[NSDate alloc] init];
        }
        [self cancelCurrentImageLoad];
        [imageView setImage:nil];
    }
}

- (void)cancelCurrentImageLoad
{
    [[App webImageManager] cancelForDelegate:self size:_size andURL:_currentURL];
    [self stopPulseAnimation];
    [imageView setAlpha:1];
    isImageLoaded = NO;
}

- (void)setPriority:(NSOperationQueuePriority)priority
{
    [[App webImageManager] setPriority:priority forDelegate:self size:_size andURL:_currentURL];
}

- (void)webImageManager:(WebImageManager *)imageManager didFinishWithImage:(UIImage *)image
{
    [self performSelectorOnMainThread:@selector(handleImageLoad:) withObject:image waitUntilDone:NO];
}

- (void)handleImageLoad:(UIImage *)image
{
    [imageView setImage:image];
    [self setNeedsLayout];
    [self stopPulseAnimation];
    if (!lastBlankDate || [lastBlankDate timeIntervalSinceNow] < -0.1) {
        [self fadeIn];
    } else {
        [imageView setAlpha:1];
    }
    isImageLoaded = YES;

    if ([_delegate respondsToSelector:@selector(webImageViewDidLoad:)]) {
        [_delegate webImageViewDidLoad:self];
    }
}

#pragma mark - Animations

- (void)startPulseAnimation
{
    [background setAlpha:STATIC_BACKGROUND_ALPHA];

    if (![NSThread isMainThread]) {
        // Cannot do UIView animations on background thread, move to main
        [self performSelectorOnMainThread:@selector(startPulseAnimation) withObject:nil waitUntilDone:NO];
        return;
    }

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [background setAlpha:STATIC_BACKGROUND_ALPHA];
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:1.0
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseInOut |
                                                     UIViewAnimationOptionRepeat |
                                                     UIViewAnimationOptionAutoreverse |
                                                     UIViewAnimationOptionAllowUserInteraction
                                          animations:^{
                                              [background setAlpha:PULSE_BACKGROUND_ALPHA];
                                          }
                                          completion:^(BOOL finished){
                                              if (finished) {
                                                  [background setAlpha:STATIC_BACKGROUND_ALPHA];
                                              }
                                          }
                          ];
                     }
     ];
}

- (void)stopPulseAnimation
{
    if (![NSThread isMainThread]) {
        // Cannot do UIView animations on background thread, move to main
        [self performSelectorOnMainThread:@selector(stopPulseAnimation) withObject:nil waitUntilDone:NO];
        return;
    }

    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [background setAlpha:STATIC_BACKGROUND_ALPHA];
                     }
                     completion:^(BOOL finished){
                         [background setAlpha:STATIC_BACKGROUND_ALPHA];
                     }
     ];
}

- (void)fadeIn
{
    if (![NSThread isMainThread]) {
        // Cannot do UIView animations on background thread, move to main
        [self performSelectorOnMainThread:@selector(fadeIn) withObject:nil waitUntilDone:NO];
        return;
    }

    [UIView animateWithDuration:.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [imageView setAlpha:1];
                     }
                     completion:nil];
}

- (void)layoutSubviews
{
    [background setFrame:[self bounds]];
    [imageView setFrame:[self bounds]];

    // layout applies only to Grid size, interpreted as meaning in gallery view
    if (_size != WebImageManagerSizeGrid)
        return;

    BOOL isSmaller = NO;

    if (isImageLoaded) {
        isSmaller = [CGRectUtils isSize:[[imageView image] size] smallerThanSize:[self bounds].size];
        [imageView setContentMode:(isSmaller ? UIViewContentModeCenter : UIViewContentModeScaleAspectFill)];
    }
}

- (void)webImageManager:(WebImageManager *)imageManager didFailWithError:(NSError *)error
{
    // TODO: Offline image/text?
    [self performSelectorOnMainThread:@selector(handleImageFailure) withObject:nil waitUntilDone:NO];
}

- (void)handleImageFailure
{
    [self stopPulseAnimation];
    isImageLoaded = NO;
}

@end
