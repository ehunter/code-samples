/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "ClusterImageView.h"
#import "WebImageManager.h"
#import "UIColor+WovenColors.h"
#import "WebImageView.h"
#import "ThreadTableViewCell.h"
#import "MemoryLaneKit/MemoryLaneKit.h"
#import <MemoryLaneKit/WovenURLConstructor.h>
// TESTING - you can change this to 1-6 to test image layout
#define MAX_IMAGES 6

@interface ClusterImageView () <WebImageViewDelegate, ThreadTableViewCellImageProtocol>
{
    NSMutableArray *imageViews;
    NSArray *currentImagesData;
    UIActivityIndicatorView *activityIndicator;
}

- (void)reload;

@end

@implementation ClusterImageView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:CGRectZero])) {
        [self setIsAccessibilityElement:YES];
        [self setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitImage];

        imageViews  = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)layoutSubviews
{
    const int gutter = 2;
    int previousImageX = 0;
    int previousImageY = 0;
    int lastImageX = 0;
    int lastImageY = 0;
    int width = [self bounds].size.width;
    int height = [self bounds].size.height;
    int largestWidth = width;
    int largestHeight = height;
    int count = 0;

    WebImageView *previousImage = nil;
    WebImageView *lastImage = nil;

    if (width > 0 && height > 0 && ![imageViews count]) {
        // Image views need to be loaded now that we have a size
        [self reload];
    }

    //count backwards when laying out
    for (int i = [imageViews count]; i > 0; i--) {
        WebImageView *imageView = imageViews[i-1];
        [imageView setFrame:CGRectMake(0, 0, largestWidth, largestHeight)];
        [imageView setBackgroundColor:[UIColor wovenDisabledGrayColor]];

        if (previousImage) {
            [previousImage setFrame:CGRectMake(previousImageX, previousImageY, width, height)];
        }

        if (lastImage) {
            [lastImage setFrame:CGRectMake(lastImageX, lastImageY, width, height)];
        }

        lastImage = imageViews[[imageViews count]-1];
        previousImage = imageViews[i-1];

        previousImageX = lastImageX;
        previousImageY = lastImageY;

        switch (count) {
            case 0:
                height = (height - gutter) / 2;
                largestHeight = (i == [imageViews count]) ? height : largestHeight;
                largestWidth = (i == [imageViews count]) ? width : largestWidth;
                lastImageY += (height + gutter);
                lastImageX += 0;
                count = 1;
                break;
            case 1:
                width = (width - gutter) / 2;
                lastImageX += (width + gutter);
                lastImageY += 0;
                count = 0;
                break;
            default:
                break;
        }
    }

    // once all the image views have been laid out set the pretzel urls for each using their bounds.
    // pretzel is Litl's own internal auto-crop service
    if (currentImagesData) {
        for (int i = 0; i < [imageViews count]; i++) {
            WebImageView *imageView = imageViews[i];
            [imageView setImageWithURL:[self urlForId:i fromDataSet:currentImagesData]];
        }
    }

    if (activityIndicator) {
        [activityIndicator setCenter:CGPointMake(width / 2, height / 2)];
    }
}

- (void)clearImages
{
    for (WebImageView *image in imageViews) {
        [image cancelCurrentImageLoad];
        [image setDelegate:nil];
        [image removeFromSuperview];
    }

    [imageViews removeAllObjects];

    _isImageLoaded = NO;
}

- (void)setImageData:(NSArray *)images
{
    NSArray *oldImages = currentImagesData;
    currentImagesData = [[images subarrayWithRange:NSMakeRange(0, MIN(MAX_IMAGES, [images count]))] retain];

    // clear images if the array counts dont match
    if ([currentImagesData count] != [oldImages count]) {
        [self clearImages];
    } else {
        // ... or if all the new (current) images do not have the indentical absolute URL to the previous
        // corresponding image in that slot.
        for (NSInteger i = 0; i < [currentImagesData count]; i++) {
            NSString *oldUrl = [[self urlForId:i fromDataSet:oldImages] absoluteString];
            NSString *newUrl = [[self urlForId:i fromDataSet:currentImagesData] absoluteString];
            if (![oldUrl isEqualToString:newUrl]) {
                [self clearImages];
                break;
            }
        }
    }

    // always reload, something in the albumData may have changed, like the cover thumbnail
    [self reload];
    [oldImages release];
}

- (void)reload
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    if (![currentImagesData count]) {
        [self clearImages];
        [self showActivityIndicator:YES];
        return;
    }

    if ([self bounds].size.width > 0 && [self bounds].size.height > 0) {
        for (int i = 0; i < [currentImagesData count]; i++)
        {
            WebImageView *imageView = nil;

            if ([imageViews count] <= i) {
                imageView = [[WebImageView alloc] initWithSize:WebImageManagerSizeFull];
                [imageView setDelegate:self];
                [imageView setBackgroundColor:[UIColor wovenOffWhiteColor]];
                [imageView setContentMode:UIViewContentModeScaleAspectFill];
                [imageView setClipsToBounds:YES];
                [self addSubview:imageView];
                [imageViews addObject:imageView];
                [imageView release];
            } else {
                imageView = imageViews[i];
            }
        }

        // Remove any remaining imageViews
        while ([imageViews count] > [currentImagesData count]) {
            WebImageView *imageToRemove = [imageViews lastObject];
            [imageToRemove cancelCurrentImageLoad];
            [imageToRemove setDelegate:nil];
            [imageToRemove removeFromSuperview];
            [imageViews removeLastObject];
        }
    }
}

- (void)showActivityIndicator:(BOOL)show
{
    if (show) {
        if (!activityIndicator) {
            activityIndicator = [[UIActivityIndicatorView alloc]
                                 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [activityIndicator setColor:[UIColor grayColor]];
            [self addSubview:activityIndicator];
            [self setNeedsLayout];
        }
        [activityIndicator startAnimating];
    } else {
        [activityIndicator removeFromSuperview];
        [activityIndicator release];
        activityIndicator = nil;
    }
}

- (NSURL *)urlForId:(NSUInteger)id fromDataSet:(NSArray *)data
{
    if (![imageViews count] || ![data count]) {
        return nil;
    }

    CGSize size = [(WebImageView *)imageViews[id] bounds].size;

    if (size.width > 0 && size.height > 0) {
        return [NSURL URLWithString:[WovenURLConstructor urlForPhoto:data[id] atSize:size]];
    } else {
        return nil;
    }
}

- (void)dealloc
{
    [self clearImages];
    [imageViews release];
    [currentImagesData release];
    [activityIndicator release];

    [super dealloc];
}

# pragma mark - WebImageViewDelegate methods

- (void)webImageViewDidLoad:(WebImageView *)view
{
    _isImageLoaded = YES;

    [self showActivityIndicator:NO];
}

@end
