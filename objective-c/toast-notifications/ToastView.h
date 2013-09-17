/* Copyright 2012 litl, LLC. All Rights Reserved. */

typedef enum {
    ToastTypeDefault,
    ToastTypeToast,
    ToastTypeProgress,
    ToastTypeLeftArrow,
    ToastTypeRightArrow,
    ToastTypeBottomArrow,
    ToastTypeTopArrow,
    ToastTypeError,
} ToastType;

typedef enum {
    ToastPositionDefault,
    ToastPositionCustom,
    ToastPositionTop,
    ToastPositionMiddle,
    ToastPositionBottom,
    ToastPositionRelativeToView
} ToastPosition;

typedef enum {
    ToastAnimationTypeNone,
    ToastAnimationTypeFade,
    ToastAnimationTypeDefault
} ToastAnimationType;

@interface Toast : UIView

@property (nonatomic) ToastType type;
@property (nonatomic) ToastPosition position;
@property (nonatomic) ToastAnimationType animationType;

// only applies for ToastPositionCustom
@property (nonatomic, assign) CGPoint customPosition;

// these only apply for ToastPositionRelativeToView
@property (nonatomic, assign) UIView *viewToPositionRelativeTo;
@property (nonatomic) CGPoint relativePositionOffset;

- (id)initWithType:(ToastType)type text:(NSString *)text;
- (id)initWithType:(ToastType)type
              text:(NSString *)text
          position:(ToastPosition)position;

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;
- (void)showAndHideAfter:(NSTimeInterval)duration withAnimationType:(ToastAnimationType)animationType;

// if the sticky goes from shown to hidden (incl. alpha=0) for any reason, this clears
- (void)hidesOnFirstTouch:(BOOL)hides;

@end
