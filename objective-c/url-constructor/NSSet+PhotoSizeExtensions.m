/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "NSSet+PhotoSizeExtensions.h"
#import "WovenPhoto.h"
#import "WovenPhotoSize.h"
#import "WovenVideoSize.h"

@implementation NSSet (PhotoSizeExtensions)

- (WovenPhotoSize *)largestWidthPhotoSize
{
    WovenPhotoSize *current = nil;
    for (WovenPhotoSize *photoSize in self) {
        if (!current || photoSize.width.intValue > current.width.intValue) {
            current = photoSize;
        } else if (photoSize.width.intValue == current.width.intValue &&
            [current.url compare:photoSize.url] == NSOrderedDescending) {
            // we have more than 1 url with the same width! Always use the same one, lowest alphabetically
            current = photoSize;
        }
    }

    return current;
}

- (WovenPhotoSize *)smallestWidthPhotoSize
{
    WovenPhotoSize *current = nil;
    for (WovenPhotoSize *photoSize in self) {
        if (!current || photoSize.width.intValue < current.width.intValue) {
            current = photoSize;
        } else if (photoSize.width.intValue == current.width.intValue &&
                   [current.url compare:photoSize.url] == NSOrderedDescending) {
            // we have more than 1 url with the same width! Always use the same one, lowest alphabetically
            current = photoSize;
        }
    }

    return current;
}

// Pick the next biggest size based upon the largest side.
// Always returns a size larger than the bounds if one exists.
// If no photo is larger than the bounds we return the largest we have.
- (WovenPhotoSize *)bestQualityPhotoSizeForBounds:(CGSize)bounds
{
    CGFloat delta = 0;

    CGFloat closestDelta = CGFLOAT_MAX;
    WovenPhotoSize *closestSize = [self largestWidthPhotoSize];
    // TODO investigate why largestWidthPhotoSize only gets the largest width and
    // the rest of the comparison below uses the larger of width or height.
    // Because we only use this when no photo is larger than the bounds,
    // we probably don't use it that often and we don't have cases where it really matters.

    for (WovenPhotoSize *photoSize in self) {
        if (bounds.width >= bounds.height) {
            delta = [[photoSize width] floatValue] - bounds.width;
        } else {
            delta = [[photoSize height] floatValue] - bounds.height;
        }

        if (delta > 0 && delta < closestDelta) {
            closestDelta = delta;
            closestSize = photoSize;
        } else if (delta == closestDelta && [[closestSize url] compare:[photoSize url]] == NSOrderedDescending) {
            // we have more than 1 url with the same height! Always use the same one, lowest alphabetically
            closestSize = photoSize;
        }
    }

    return closestSize;
}

// Pick the closest size based upon largest bounds dimension or total area.
// Can return an image smaller or larger than the bounds. This gets us closest.
- (WovenPhotoSize *)bestFitPhotoSizeForBounds:(CGSize)bounds useArea:(BOOL)useArea
{
    CGFloat area = bounds.width * bounds.height;
    CGFloat dim = bounds.width > bounds.height ? bounds.width : bounds.height;

    CGFloat closestDelta = CGFLOAT_MAX;
    WovenPhotoSize *closestSize = nil;

    for (WovenPhotoSize *photoSize in self) {
        CGFloat delta = 0.0f;
        if (useArea) {
            CGFloat photoArea = [[photoSize width] floatValue] * [[photoSize height] floatValue];
            delta = abs(area - photoArea);
        } else {
            CGFloat w = [[photoSize width] floatValue];
            CGFloat h = [[photoSize height] floatValue];
            CGFloat photoDim = w > h ? w : h;
            delta = abs(dim - photoDim);
        }
        if (delta < closestDelta) {
            closestSize = photoSize;
            closestDelta = delta;
        } else if (delta == closestDelta && [[closestSize url] compare:[photoSize url]] == NSOrderedDescending) {
            // we have more than 1 url with the same area! Always use the same one, lowest alphabetically
            closestSize = photoSize;
        }
    }

    return closestSize;
}

- (WovenVideoSize *)bestFitVideoSizeForBounds:(CGSize)bounds useArea:(BOOL)useArea
{
    CGFloat area = bounds.width * bounds.height;
    CGFloat dim = bounds.width > bounds.height ? bounds.width : bounds.height;

    CGFloat closestDelta = CGFLOAT_MAX;
    WovenVideoSize *closestSize = nil;

    for (WovenVideoSize *photoSize in self) {
        CGFloat delta = 0.0f;
        if (useArea) {
            CGFloat photoArea = [[photoSize width] floatValue] * [[photoSize height] floatValue];
            delta = abs(area - photoArea);
        } else {
            CGFloat w = [[photoSize width] floatValue];
            CGFloat h = [[photoSize height] floatValue];
            CGFloat photoDim = w > h ? w : h;
            delta = abs(dim - photoDim);
        }
        if (delta < closestDelta) {
            closestSize = photoSize;
            closestDelta = delta;
        } else if (delta == closestDelta && [[closestSize url] compare:[photoSize url]] == NSOrderedDescending) {
            // we have more than 1 url with the same area! Always use the same one, lowest alphabetically
            closestSize = photoSize;
        }
    }

    return closestSize;
}

// Pick biggest size based upon the largest side that fits within and does not exceed the bounds.
// Always returns a size smaller than the bounds if one exists otherwise picks the smallest width.
// This makes sure both dimensions of the photo fit.
- (WovenPhotoSize *)bestPhotoSizeWithinBounds:(CGSize)bounds
{
    BOOL useBestWidth = bounds.width >= bounds.height ? YES : NO;

    CGFloat closestDelta = CGFLOAT_MAX;
    WovenPhotoSize *closestSize = [self smallestWidthPhotoSize];

    for (WovenPhotoSize *photoSize in self) {
        CGFloat delta = -1.0;
        if (useBestWidth) {
            // Get the widest photo that fits within the bounds so long as the height does too.
            if ([[photoSize height] floatValue] <= bounds.height) {
                delta = bounds.width - [[photoSize width] floatValue];
            }
        } else {
            // For Accedos TV the bounds passed in is always wider than height so the
            // else condition is never hit. Included for completeness.
            // Get the tallest photo that fits within the bounds so long as the width does too.
            if ([[photoSize width] floatValue] <= bounds.width) {
                delta = bounds.height - [[photoSize height] floatValue];
            }
        }

        if (delta >= 0 && delta < closestDelta) {
            closestDelta = delta;
            closestSize = photoSize;
        } else if (delta == closestDelta && [[closestSize url] compare:[photoSize url]] == NSOrderedDescending) {
            // we have more than 1 url with the same height! Always use the same one, lowest alphabetically
            closestSize = photoSize;
        }
    }

    return closestSize;
}

@end
