/* Copyright 2012 litl, LLC. All Rights Reserved. */

@interface ClusterImageView : UIView

@property (nonatomic, readonly) BOOL isImageLoaded;

- (void)clearImages;
// this needs to be an array of WovenPhoto objects with a capacity of 1-6
- (void)setImageData:(NSArray *)images;

@end