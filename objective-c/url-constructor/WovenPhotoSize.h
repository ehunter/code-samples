/* Copyright 2011 litl, LLC. All Rights Reserved. */

#import <CoreData/CoreData.h>
#import "WovenManagedObject.h"

@interface WovenPhotoSize : WovenManagedObject

@property (nonatomic, retain) NSNumber *width;
@property (nonatomic, retain) NSNumber *height;
@property (nonatomic, copy) NSString *url;

@property (readwrite, retain) NSNumber *shouldFault;

@end
