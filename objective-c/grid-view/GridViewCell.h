/* Copyright 2012 litl, LLC. All Rights Reserved. */

@class WebImageView;

@interface GridViewCell : UICollectionViewCell

@property (nonatomic, copy) NSString *photoId;
@property (nonatomic, readonly) BOOL isImageLoaded;
@property (nonatomic, readonly, retain) WebImageView *imageView;

- (void)setPhotoURL:(NSURL *)url priority:(NSOperationQueuePriority)priority label:(NSString *)label;
- (void)cancelPendingImageLoad;
- (void)reset;
- (void)setPriority:(NSOperationQueuePriority)priority;
- (void)showTVIconIfNeeded:(BOOL)show;
- (void)showVideoLabel:(BOOL)isVideo duration:(NSNumber *)duration;

@end
