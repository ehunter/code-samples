/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "UIColor+WovenColors.h"
#import <QuartzCore/QuartzCore.h>
#import "WebImageView.h"
#import "ExternalDisplayManager.h"
#import "GridViewCell.h"
#import "ActionManager.h"
#import "UIFont+WovenSizes.h"
#import "UILabel+TextHeight.h"

@interface GridViewCell ()
{
    CGSize lastSize;
    UIImageView *tvIcon;
    UILabel *videoDuration;
}
@end

@implementation GridViewCell

#pragma mark - overrides

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self == nil) {
        return nil;
    }

    [self setIsAccessibilityElement:YES];
    [self setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitImage];

    _imageView = [[WebImageView alloc] initWithSize:WebImageManagerSizeGrid];
    [_imageView setBackgroundColor:[UIColor whiteColor]];
    [_imageView setContentMode:UIViewContentModeCenter];
    [_imageView setClipsToBounds:YES];
    [[_imageView layer] setBorderWidth:1.0f];
    [[_imageView layer] setBorderColor:[[UIColor wovenMiddleGrayColor] CGColor]];
    [[self contentView] addSubview:_imageView];

    return self;
}

- (void)dealloc
{
    [_imageView removeFromSuperview];
    [_imageView release];

    [tvIcon removeFromSuperview];
    [tvIcon release];

    [videoDuration removeFromSuperview];
    [videoDuration release];

    [_photoId release];

    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGSize size = [self frame].size;
    [_imageView setFrame:CGRectMake(0, 0, size.width, size.height)];

    if (videoDuration) {
        CGFloat h = [videoDuration textHeight];
        CGSize fitsSize = [videoDuration sizeThatFits:CGSizeMake(size.width, 9999)];
        CGFloat w = fitsSize.width + 10;
        [videoDuration setFrame:CGRectMake(size.width - w , size.height - h, w, h)];
        [self bringSubviewToFront:videoDuration];
    }

    if (tvIcon) {
        CGFloat scale = (size.width / [[tvIcon image] size].width);
        CGFloat iconHeight = [[tvIcon image] size].height * scale;
        [tvIcon setFrame:CGRectMake(0, size.height - iconHeight, size.width, iconHeight)];
        [self bringSubviewToFront:tvIcon];
    }

    [[App actionManager] layoutOverlayOnView:[self contentView] withFrame:[_imageView frame]];
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    [self clearImage];
}

#pragma mark - private methods

- (void)clearImage
{
    [self cancelPendingImageLoad];
    [_imageView setImageWithURL:nil];
    [_imageView setBackgroundColor:[UIColor whiteColor]];
    [videoDuration removeFromSuperview];
    [videoDuration release];
    videoDuration = nil;
}

- (void)showTVIconIfNeeded:(BOOL)show
{
    BOOL showIcon = show && _photoId && [[App externalDisplayManager] isShowingPhotoId:_photoId];

    if (showIcon) {
        if (!tvIcon) {
            tvIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sandt-overlay.png"]];
            [tvIcon setContentMode:UIViewContentModeScaleAspectFit];
            [self addSubview:tvIcon];
            [self setNeedsLayout];
        }
    } else if (tvIcon) {
        [tvIcon removeFromSuperview];
        [tvIcon release];
        tvIcon = nil;
    }

    // Since the background is white, 0.8 alpha is the same as a 20% white overlay
    [_imageView setAlpha: showIcon ? 0.8 : 1];
}

#pragma mark - public methods

- (void)setPhotoId:(NSString *)photoId
{
    NSString *tempString = [photoId copy];
    [_photoId release];
    _photoId = tempString;

    // because the tv icon visibility is linked to the selected photo id in TVClient we
    // need to refresh the tv icons visibility every time this is reset
    [self showTVIconIfNeeded:YES];
}

- (void)setPhotoURL:(NSURL *)url priority:(NSOperationQueuePriority)priority label:(NSString *)label
{
    [self setAccessibilityLabel:label];
    [_imageView setImageWithURL:url priority:priority];
    [self setNeedsLayout];
}

- (void)cancelPendingImageLoad
{
    [_imageView cancelCurrentImageLoad];
}

- (void)setPriority:(NSOperationQueuePriority)priority
{
    [_imageView setPriority:priority];
}

- (void)reset
{
    [self setPhotoId:nil]; // this clears TV icon
    [self clearImage];
    [[self contentView] setNeedsDisplay];
}

- (BOOL)isImageLoaded
{
    return [_imageView image] != nil;
}

- (void)showVideoLabel:(BOOL)isVideo duration:(NSNumber *)duration
{
    if (isVideo) {
        if (!videoDuration) {
            videoDuration = [[UILabel alloc] initWithFrame:CGRectZero];
            [videoDuration setBackgroundColor:[UIColor blackColor]];
            [videoDuration setTextColor:[UIColor whiteColor]];
            [videoDuration setFont:[UIFont wovenMediumFont]];
            [videoDuration setNumberOfLines:1];
            [videoDuration setTextAlignment:NSTextAlignmentCenter];
            [self addSubview:videoDuration];
        }

        NSUInteger sec = [duration integerValue];
        [videoDuration setText:(!sec ? @"VIDEO" : [NSString stringWithFormat:@"%02d:%2d", (sec / 60), (sec % 60)])];
        [self setNeedsLayout];
    } else if (videoDuration) {
        [videoDuration removeFromSuperview];
        [videoDuration release];
        videoDuration = nil;
    }
}

@end
