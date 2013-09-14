/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import <CoreData/CoreData.h>
#import "WovenPrunableObject.h"
#import "WovenManagedObject.h"

@class WovenPhoto;

typedef enum {
    WovenGroupTypeAlbum = 0,   // Regular album, shows up in the albums tab
    WovenGroupTypeFeedAlbum,   // Albums in the thread tab, but not in the albums tab
    WovenGroupTypeFeedCluster,  // Microevents, show in the thread tab only
    WovenGroupTypeLocalMicroevent,
    WovenGroupTypeLocalWiggle
} WovenGroupType;

extern NSString * const kWovenGroupIdKey;
extern NSString * const kWovenGroupTypeKey;

// Constants corresponding to the group type sent to the server. Mapped to groupTypeName in WovenGroup
extern NSString * const kWovenGroupTypeNameAlbum;
extern NSString * const kWovenGroupTypeNameSource;
extern NSString * const kWovenGroupTypeNameUser;
extern NSString * const kWovenGroupTypeNameMicroevent;
extern NSString * const kWovenGroupTypeNameWiggle;
extern NSString * const kWovenGroupTypeNameWordgroup;
extern NSString * const kWovenGroupTypeNameShare;
extern NSString * const kWovenGroupSourceTypeIOS;

extern NSString * const kWovenGroupSortFieldOldestToNewest;
extern NSString * const kWovenGroupSortFieldNewestToOldest;

@interface WovenGroup : WovenManagedObject <WovenPrunableObject>

@property (readwrite, copy) NSString *groupId;
@property (readwrite, copy) NSString *title;
@property (nonatomic, copy) NSString *sourceType;
@property (readwrite, retain) NSDate *date;
@property (readwrite, retain) NSSet *coverSizes;
@property (readwrite, retain) WovenPhoto *coverPhoto;
@property (readwrite, copy) NSString *sourceId;
@property (readwrite, retain) NSNumber *groupType;
@property (readwrite, copy) NSString *groupTypeName;
@property (readwrite, retain) NSNumber *isGroupDeleted;
@property (readwrite, retain) NSString *sortField;
@property (nonatomic, copy) NSString *rid;

+ (NSFetchRequest *)fetchRequestForAll;
+ (NSFetchRequest *)fetchRequestForAllMicroevents;
+ (NSFetchRequest *)fetchRequestForAllWiggles;
+ (NSFetchRequest *)fetchRequestForAllMicroeventsAndWiggles;
+ (NSFetchRequest *)fetchRequestForGroupId:(NSString *)groupId;
+ (NSFetchRequest *)fetchRequestForSourceId:(NSString *)sourceId;
+ (NSArray *)groupsMatchingDeviceAlbumName:(NSString *)name;
+ (NSNumber *)numberOfGroupsWithSourceId:(NSString *)sourceId;
+ (NSArray *)allMicroevents;

- (NSSet *)coverPhotoSizes;
- (NSString *)albumTitle;
- (NSString *)description;

@end
