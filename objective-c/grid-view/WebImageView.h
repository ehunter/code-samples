/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "WebImageManager.h"

@class WebImageView;
@protocol WebImageViewDelegate;

@interface WebImageView : UIView

@property (readonly, copy) NSURL *currentURL;
@property (readonly) WebImageManagerSize size;
@property (readwrite, assign) id<WebImageViewDelegate> delegate;
@property (nonatomic, readonly) UIImage *image;

- (id)initWithSize:(WebImageManagerSize)size;
- (void)setImageWithURL:(NSURL *)url;
- (void)setImageWithURL:(NSURL *)url priority:(NSOperationQueuePriority)priority;
- (void)cancelCurrentImageLoad;
- (void)setPriority:(NSOperationQueuePriority)priority;
- (void)setWovenBabicon;

@end

@protocol WebImageViewDelegate <NSObject>

@optional
- (void)webImageViewDidLoad:(WebImageView *)view;

@end
