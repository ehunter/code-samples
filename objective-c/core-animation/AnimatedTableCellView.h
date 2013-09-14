/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import <QuartzCore/QuartzCore.h>

@interface AlbumTableCellView : UITableViewCell

@property (readwrite) BOOL landscape;

- (void)flipImageInWithDuration:(float)duration andDelay:(float)delay;

@end