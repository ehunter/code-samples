/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "AnimatedTableCellView.h"
#import "Constants.h"
#import <CoreGraphics/CoreGraphics.h>

#define IMAGE_WIDTH 308

@interface AnimatedTableCellView : UITableViewCell {
    UIView *cellImageView;
    CALayer *imageAnimationLayer;
    BOOL isTransitioning;
}

- (CAAnimation *)flipAnimationWithDuration:(NSTimeInterval)aDuration andDelay:(float)delay;

@end

@implementation AnimatedTableCellView

@synthesize animatedTableCellView;
@synthesize landscape;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {

    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier])) {
        cellImageView = [[UIView alloc] init];
        [cellImageView setFrame:CGRectMake(GRID_IMAGE_MARGIN, 0, IMAGE_WIDTH,
                                           (self.bounds.size.height - GRID_IMAGE_MARGIN))];
        [cellImageView setBackgroundColor:[UIColor lightGrayColor]];
        [[self contentView] addSubview:cellImageView];

        // in order to get rid of the default blue selected bg we have to set it to a custom UIView
        UIView *selectedBgView = [[UIView alloc] init];
        [selectedBgView setBackgroundColor:[UIColor whiteColor]];
        [self setSelectedBackgroundView:selectedBgView];
        [selectedBgView release];
    }
    return self;
}

- (void)flipImageInWithDuration:(float)duration andDelay:(float)delay
{
    if (isTransitioning) {
        return;
    }

    imageAnimationLayer = [cellImageView layer];
    imageAnimationLayer.frame = CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.height);
    [self.layer addSublayer:imageAnimationLayer];

    imageAnimationLayer.opacity = 0;

	CAAnimation *topAnimation = [self flipAnimationWithDuration:duration andDelay:delay];

    CGFloat zDistance = 1500.0f;
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = -1. / zDistance;
    imageAnimationLayer.transform = perspective;

    topAnimation.delegate = self;
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        NSLog(@"FLIP IN ANIMATION COMPLETE");
        isTransitioning = NO;
    }];
    [imageAnimationLayer addAnimation:topAnimation forKey:@"flipIn"];
    [CATransaction commit];
}

-(CAAnimation *)flipAnimationWithDuration:(NSTimeInterval)aDuration andDelay:(float)delay
{
	isTransitioning = YES;
    CABasicAnimation *flipAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
    CGFloat startValue = 90.0f * M_PI / 180.0f;
    CGFloat endValue = 0.0f;
    flipAnimation.duration = aDuration;
    flipAnimation.fromValue = [NSNumber numberWithDouble:startValue];
    flipAnimation.toValue = [NSNumber numberWithDouble:endValue];
    flipAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    CABasicAnimation *fadeInAnimation;
    fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeInAnimation.toValue = [NSNumber numberWithFloat:1];
    fadeInAnimation.duration = aDuration + .25;
    fadeInAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];

    // Combine the flipping and fading into one animation
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = [NSArray arrayWithObjects:flipAnimation, fadeInAnimation, nil];

    animationGroup.duration = aDuration + .25;
    animationGroup.beginTime = CACurrentMediaTime() + delay;

    // Hold the view in the state reached by the animation until we can fix it, or else we get an annoying flicker
	// this really means keep the state of the object at whatever the anim ends at
    animationGroup.fillMode = kCAFillModeForwards;
    animationGroup.removedOnCompletion = NO;

    return animationGroup;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    CGRect frame = [layer frame];
    frame.origin = CGPointZero;
    [imageAnimationLayer setFrame:frame];
    [super layoutSublayersOfLayer:layer];
}

- (void)layoutSubviews
{
    if ([self landscape]) {
        // in landscape orientation the image needs to be centered in the cell
        [cellImageView setFrame:CGRectMake((GRID_IMAGE_MARGIN + ((self.bounds.size.width - IMAGE_WIDTH) / 2)),
                                           0,
                                           IMAGE_WIDTH,
                                           (self.bounds.size.height - GRID_IMAGE_MARGIN))];
    } else {
        [cellImageView setFrame:CGRectMake(GRID_IMAGE_MARGIN,
                                           0,
                                           IMAGE_WIDTH,
                                           (self.bounds.size.height - GRID_IMAGE_MARGIN))];
    }
}

- (void)dealloc {
    [cellImageView release];
    [imageAnimationLayer release];
    [super dealloc];
}

@end
