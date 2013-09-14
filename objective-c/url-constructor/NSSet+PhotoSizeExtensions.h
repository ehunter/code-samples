/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class WovenPhotoSize;
@class WovenVideoSize;

@interface NSSet (PhotoSizeExtensions)

- (WovenPhotoSize *)largestWidthPhotoSize;
- (WovenPhotoSize *)smallestWidthPhotoSize;
- (WovenPhotoSize *)bestQualityPhotoSizeForBounds:(CGSize)bounds;
- (WovenPhotoSize *)bestFitPhotoSizeForBounds:(CGSize)bounds useArea:(BOOL)useArea;
- (WovenPhotoSize *)bestPhotoSizeWithinBounds:(CGSize)bounds;
- (WovenVideoSize *)bestFitVideoSizeForBounds:(CGSize)bounds useArea:(BOOL)useArea;

@end
