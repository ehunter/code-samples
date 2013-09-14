/* Copyright 2011 litl, LLC. All Rights Reserved. */

#import "WovenPhotoSize.h"

@implementation WovenPhotoSize

@dynamic width;
@dynamic height;
@dynamic url;

@dynamic shouldFault;

- (void)didSave
{
    [super didSave];
    if ([[self shouldFault] boolValue]) {
        [[self managedObjectContext] refreshObject:self mergeChanges:NO];
    }
}

@end
