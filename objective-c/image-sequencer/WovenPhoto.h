/* Copyright 2011 litl, LLC. All Rights Reserved. */

#import <CoreData/CoreData.h>
#import "WovenPrunableObject.h"
#import "WovenManagedObject.h"

@class WovenGroup;

extern NSString * const kAllGroupIds; // default for groupIds
extern NSString * const kWovenPhotoIdKey;
extern NSString * const kWovenGroupIdsKey;
extern NSString * const kWovenDateKey; // used in group too, but this header gets everywhere its needed
extern NSString * const kWovenIsPhotoDeletedKey;

// used in group too, but this header gets everywhere it's needed
extern NSString * const kWovenDateKey;
extern NSString * const kWovenRidKey;
extern NSString * const kWovenSourceIdKey;

typedef enum {
    WovenPhotoOrientationLandscape = 0,
    WovenPhotoOrientationPortrait = 1,
    WovenPhotoOrientationSquare = 2,
} WovenPhotoOrientation;

@interface WovenPhoto : WovenManagedObject <WovenPrunableObject>

@property (nonatomic, copy) NSString *photoId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *photoURL;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSSet *sizes;
@property (nonatomic, copy) NSString *sourceType;
@property (nonatomic, copy) NSString *sourceId;
@property (nonatomic, retain) NSNumber *skipForTimeline;
@property (nonatomic, copy) NSString *groupIds;
@property (nonatomic, retain) NSSet *coverPhotoGroups;
@property (nonatomic, retain) NSNumber *isPhotoDeleted;
@property (nonatomic, retain) NSString *gridThumbnailLarge; // TODO: shouldn't these two be "copy" properties?
@property (nonatomic, retain) NSString *gridThumbnailSmall;
@property (nonatomic, copy) NSString *rid;
@property (nonatomic, retain) NSNumber *isVideo;
@property (nonatomic, retain) NSNumber *videoDuration; // sizes contains video info
@property (nonatomic, retain) NSSet *videoSizes;
@property (nonatomic, copy) NSString *thumbIds;
@property (nonatomic, retain) NSNumber *visualDiff;
@property (nonatomic, copy) NSString *wiggleId;

+ (NSFetchRequest *)fetchRequestForPage:(NSUInteger)pageNumber
                               pageSize:(NSUInteger)pageSize;
+ (NSFetchRequest *)fetchRequestForGroup:(WovenGroup *)group orderAscending:(BOOL)orderAscending;
+ (NSFetchRequest *)fetchRequestForAllWithOrderAscending:(BOOL)orderAscending;
+ (NSFetchRequest *)fetchRequestForAllWithGroupId:(NSString *)groupId orderAscending:(BOOL)orderAscending;
+ (NSNumber *)numberOfPhotosWithSourceId:(NSString *)sourceId;
+ (NSArray *)allPhotosOldestToNewest;
+ (NSArray *)photosWithGroupId:(NSString *)groupId;

- (NSArray *)groups;
- (NSString *)description;

- (BOOL)addGroupId:(NSString *)groupId;
- (BOOL)removeGroupId:(NSString *)groupId;

@end
