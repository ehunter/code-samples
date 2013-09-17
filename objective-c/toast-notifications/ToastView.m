/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "ToastView.h"
#import "UIFont+CustomSizes.h"
#import "QuartzCore/CALayer.h"
#import "UIManager.h"

#define DEFAULT_TOAST_DELAY 4
#define DEFAULT_FADE_DURATION .35
#define FLAG_HEIGHT 9
#define SHADOW_WIDTH 3
#define SIDE_ARROW_WIDTH 20

@interface ToastView ()
{
    UIView *mainView;
    UIImageView *backgroundView;
    UILabel *titleLabel;
    UIActivityIndicatorView *spinner;
    BOOL hidesOnFirstTouch;
}
@end

@implementation ToastView

- (id)initWithType:(ToastType)type text:(NSString *)text
{
    return [self initWithType:type text:text position:ToastPositionDefault];
}

- (id)initWithType:(ToastType)type
              text:(NSString *)text
          position:(ToastPosition)position
{
    if (!(self = [super initWithFrame:CGRectZero])) {
        return nil;
    }

    mainView = [[UIView alloc] initWithFrame:CGRectZero];

    backgroundView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [backgroundView setBackgroundColor:[UIColor clearColor]];
    [backgroundView setAlpha:.9];
    [mainView addSubview:backgroundView];

    titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [titleLabel setText:text];
    [titleLabel setNumberOfLines:2];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setFont:[UIFont customBodyBoldFont]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [mainView addSubview:titleLabel];

    [[self layer] setShadowColor:[UIColor blackColor].CGColor];
    [[self layer] setShadowOffset:CGSizeMake(1, SHADOW_WIDTH)];
    [[self layer] setShadowOpacity:.7];
    [[self layer] setShadowRadius:SHADOW_WIDTH];
    [self setClipsToBounds:NO];

    [self setPosition:position];
    [self setType:type];
    [self addSubview:mainView];

    return self;
}

- (void)dealloc
{
    [self litl_doNotNotifyMe:kUIManagerTouchesDidHappen];
    [mainView release];
    [backgroundView release];
    [titleLabel release];
    [spinner release];

    [super dealloc];
}

#pragma mark - layout

- (void)layoutInsideMainView
{
    const CGFloat kTwoThirds = 2.0f / 3.0f;
    const CGFloat kPadding = 10;
    const CGFloat kSpinnerWidth = 20;
    //const CGFloat kSideArrowWidth = 40;

    CGSize superviewSize = [[self superview] bounds].size;

    CGSize maxLabelWidth = CGSizeMake(fminf(superviewSize.width * kTwoThirds, 350), 9999);
    CGSize labelSize = [[titleLabel text] sizeWithFont:[titleLabel font]
                                     constrainedToSize:maxLabelWidth
                                         lineBreakMode:NSLineBreakByWordWrapping];

    CGFloat width = labelSize.width + (kPadding * 2);
    CGFloat height = labelSize.height + (kPadding * 2);
    width += spinner ? (kPadding + kSpinnerWidth) : 0;
    width += ((_type == ToastTypeRightArrow) ||
              (_type == ToastTypeLeftArrow)) ? SIDE_ARROW_WIDTH : 0;

    CGFloat backgroundHeight = ((_type == ToastTypeTopArrow) ||
                                (_type == ToastTypeBottomArrow)) ? height + FLAG_HEIGHT : height;

    [backgroundView setFrame:CGRectMake(0, 0, width, backgroundHeight)];

    CGFloat y = 0;
    CGFloat x = 0;

    if (spinner) {
        x += kPadding;
        [spinner setFrame:CGRectMake(x, y + ((height - kSpinnerWidth) / 2), kSpinnerWidth, kSpinnerWidth)];
        x += kSpinnerWidth;
    }

    x += kPadding + ((_type == ToastTypeLeftArrow) ? SIDE_ARROW_WIDTH: 0);

    CGFloat centerY = (height - labelSize.height) / 2;
    y += centerY + ((_type == ToastTypeTopArrow) ? FLAG_HEIGHT : 0);

    [titleLabel setFrame:CGRectMake(x, y, labelSize.width, labelSize.height)];
}

- (void)layoutSubviews
{
    [self layoutInsideMainView];
    [mainView setBounds:[backgroundView bounds]];
    CGRect frame = [mainView frame];
    frame.origin = [self originAsCalculated];
    [mainView setFrame:frame];
}

- (CGPoint)originAsCalculatedRelativeToView
{
    // for brevity, p(ositioning) v(iew)
    UIView *pv = _viewToPositionRelativeTo;

    if (!pv) {
        [NSException raise:@"Toast Error" format:@"No view to position relative to"];
    }

    // NOTE: presumably, you'd want to convert the coordinates of [pv center] to the view which will be displaying
    // the notification, but this didnt' work.
    // CGPoint center = [pv convertPoint:[pv center] toView:[[App UIManager] notificationSuperview]];

    CGPoint center = [pv center];
    CGFloat halfHeight = [pv bounds].size.height / 2;
    CGFloat halfWidth = [pv bounds].size.width / 2;


    // NOTE: some of these are heuristic, and the origin values may not be the *apparent* self.frame.origin, because
    // -layoutSubviews does it's own magic w.r.t. the origin, ... I think.

    CGPoint tipOfArrow;
    const CGFloat borderWidth = 3; // looks like there is a white border, about 2-3 pixels wide
    CGSize mainSize = [mainView bounds].size;
    CGPoint origin = CGPointZero;

    switch (_type) {
        case ToastTypeLeftArrow:
            tipOfArrow = CGPointMake(center.x + halfWidth , center.y);
            origin.x = tipOfArrow.x;
            origin.y = tipOfArrow.y; // layoutSubviews handles y offset
            break;

        case ToastTypeTopArrow:
            tipOfArrow = CGPointMake(center.x, center.y + halfHeight);
            origin.x = tipOfArrow.x - mainSize.width + borderWidth;
            origin.y = tipOfArrow.y + FLAG_HEIGHT;
            break;

        case ToastTypeRightArrow:
            tipOfArrow = CGPointMake(center.x - halfWidth, center.y);
            origin.x = tipOfArrow.x - mainSize.width + SIDE_ARROW_WIDTH - 10; // based on layoutSubviews
            origin.y = tipOfArrow.y; // layoutSubviews handles y offset
            break;

        case ToastTypeBottomArrow:
            tipOfArrow = CGPointMake(center.x, center.y - halfHeight);
            origin.x = tipOfArrow.x + SHADOW_WIDTH + borderWidth;
            origin.y = tipOfArrow.y - FLAG_HEIGHT - 10;
            break;

        default:
            NSLog(@"unhandled ToastType");
    }
    return origin;
}

- (CGPoint)originAsCalculated
{
    if (_position == ToastPositionRelativeToView) {
        return [self originAsCalculatedRelativeToView];
    }

    CGFloat y = 0;
    CGFloat x = 0;
    CGSize superviewSize = [[self superview] bounds].size;
    CGFloat width = [mainView bounds].size.width;
    CGFloat heightInThirds = superviewSize.height / 3;

    switch (_position) {
        case ToastPositionTop:
            y = heightInThirds - (heightInThirds / 2);
            break;
        case ToastPositionBottom:
            y = heightInThirds * 2 + (heightInThirds / 2);
            break;
        case ToastPositionCustom:
            y = _customPosition.y;
            break;
        case ToastPositionMiddle:
        case ToastPositionDefault:
        default:
            y = superviewSize.height / 2;
            break;
    }

    x = (_position == ToastPositionCustom) ? _customPosition.x : ((superviewSize.width / 2) - (width / 2));
    return CGPointMake(x, y);
}

#pragma mark - properties

- (void)setType:(ToastType)type
{
    _type = type;

    if (spinner) {
        [spinner removeFromSuperview];
        [spinner release];
        spinner = nil;
    }

    switch (type) {
        case ToastTypeLeftArrow:
            [backgroundView setTransform:CGAffineTransformMakeRotation(M_PI)];
        case ToastTypeRightArrow:
            [backgroundView setImage:[[UIImage imageNamed:@"toast-arrow.png"]
                                      resizableImageWithCapInsets:UIEdgeInsetsMake(15, 5, 15, 25)]];
            break;
        case ToastTypeBottomArrow:
            [backgroundView setTransform:CGAffineTransformMakeRotation(M_PI)];
        case ToastTypeTopArrow:
            [backgroundView setImage:[[UIImage imageNamed:@"toast-flag.png"]
                                      resizableImageWithCapInsets:UIEdgeInsetsMake(13, 4, 6, 12)]];
            // top, left, bottom, right
            break;
        case ToastTypeError:
            // TODO ask design if we should use an error graphic in this instance?
            break;
        case ToastTypeProgress:
            [backgroundView setImage:[[UIImage imageNamed:@"toast-plain.png"]
                                      resizableImageWithCapInsets:UIEdgeInsetsMake(6, 6, 6, 6)]];
            spinner = [[UIActivityIndicatorView alloc]
                       initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            [spinner startAnimating];
            [mainView addSubview:spinner];
            break;
        case ToastTypeToast:
        case ToastTypeDefault:
            [backgroundView setImage:[[UIImage imageNamed:@"toast-plain.png"]
                                      resizableImageWithCapInsets:UIEdgeInsetsMake(6, 6, 6, 6)]];
            [self showAndHideAfter:DEFAULT_TOAST_DELAY withAnimationType:ToastAnimationTypeFade];
            break;
    }

    [self setNeedsLayout];
}

- (void)setAnimationType:(ToastAnimationType)animationType
{
    _animationType = animationType;
}

#pragma mark - public methods

- (void)show:(BOOL)animated
{
    if (animated) {
        [self animateViewInWithType:_animationType ?: ToastAnimationTypeDefault];
    } else {
        [self setAlpha:1];
        [self setHidden:NO];
    }
}

- (void)hide:(BOOL)animated
{
    if ([self isHidden] || [self alpha] == 0.0 ) {
        return;
    }

    if (animated) {
        [self setAlpha:1];
        [self fadeViewToAlpha:0 removeOnCompletion:YES]; // also calls -didHide
    } else {
        [self setAlpha:0];
        [self setHidden:YES];
        [self didHide];
    }
}

- (void)showAndHideAfter:(NSTimeInterval)delay withAnimationType:(ToastAnimationType)animationType
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOut) object:nil];
    [self animateViewInWithType:animationType];
    [self performSelector:@selector(fadeOut) withObject:nil afterDelay:delay];
}

- (void)hidesOnFirstTouch:(BOOL)hides
{
    if (!hidesOnFirstTouch && hides) {
        // only once when turning on
        [self litl_notifyMe:kUIManagerTouchesDidHappen selector:@selector(handleTouchesBegan)];

    } else if (!hides) {
        [self litl_doNotNotifyMe:kUIManagerTouchesDidHappen];
    }

    hidesOnFirstTouch = hides;
}

#pragma mark - private methods

- (void)animateViewInWithType:(ToastAnimationType)type
{
    switch (type) {
        case ToastAnimationTypeNone:
            [self show:NO];
            break;
        case ToastAnimationTypeFade:
        case ToastAnimationTypeDefault:
            [self setAlpha:0];
            [self fadeViewToAlpha:1 removeOnCompletion:NO];
            break;
    }
}

- (void)fadeOut
{
    [self fadeViewToAlpha:0 removeOnCompletion:YES];
}

- (void)fadeViewToAlpha:(CGFloat)alpha removeOnCompletion:(BOOL)remove
{
    [UIView animateWithDuration:DEFAULT_FADE_DURATION
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self setAlpha:alpha];
                     }
                     completion:^(BOOL finished) {
                         [self setAlpha:alpha];
                         if (alpha == 0.0) {
                             [self setHidden:YES];
                             [self didHide];
                         }
                         if (remove) {
                             [self removeFromSuperview];
                         }
                     }];
}

- (void)handleTouchesBegan
{
    if ([self isHidden]) {
        DDLogInfo(@"Receiving touch events while hidden");
    } else {
        [self hide:YES];
    }
}

// called after hidden, whatever the method
- (void)didHide
{
    [self hidesOnFirstTouch:NO];
}

@end
