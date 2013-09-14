/* Copyright 2011 litl, LLC. All Rights Reserved. */

#import "WovenPhoto.h"
#import "WovenGroup.h"
#import "WovenClient.h"

// shared keys
NSString * const kWovenDateKey = @"date";
NSString * const kWovenRidKey = @"rid";
NSString * const kWovenSourceIdKey = @"sourceId";

NSString * const kWovenPhotoIdKey = @"photoId";
NSString * const kWovenGroupIdsKey = @"groupIds";
NSString * const kWovenWiggleIdKey = @"wiggleId";
NSString * const kWovenIsPhotoDeletedKey = @"isPhotoDeleted";
NSString * const kWovenSkipForTimeLineKey = @"skipForTimeline";
NSString * const kWovenSourceTypeKey = @"sourceType";
NSString * const kWovenSampleValue = @"sample";
NSString * const kWovenPhotoTitleKey = @"title";

#define ADD YES
#define REMOVE NO

@implementation WovenPhoto

NSString * const kAllGroupIds = nil;

@dynamic photoId;
@dynamic title;
@dynamic photoURL;
@dynamic date;
@dynamic sizes;
@dynamic sourceType;
@dynamic sourceId;
@dynamic skipForTimeline;
@dynamic groupIds;
@dynamic coverPhotoGroups;
@dynamic isPhotoDeleted;
@dynamic gridThumbnailLarge;
@dynamic gridThumbnailSmall;
@dynamic rid;
@dynamic isVideo;
@dynamic videoDuration;
@dynamic videoSizes;
@dynamic thumbIds;
@dynamic visualDiff;
@dynamic wiggleId;

+ (NSString *)primaryKey
{
    return kWovenPhotoIdKey;
}

+ (NSFetchRequest *)fetchRequestForPage:(NSUInteger)pageNumber
                               pageSize:(NSUInteger)pageSize
{
    NSFetchRequest *fetchRequest = [WovenPhoto fetchRequest];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:
                                @"%K != %@", kWovenIsPhotoDeletedKey, @YES]];

    [fetchRequest setSortDescriptors:[WovenPhoto wovenPhotoSortDescriptorsAscending:YES]];
    [fetchRequest setFetchLimit:pageSize];
    [fetchRequest setFetchOffset:(pageNumber * pageSize)];
    [fetchRequest setIncludesPendingChanges:NO];
    return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestForAllWithGroupId:(NSString *)groupId orderAscending:(BOOL)orderAscending
{
    NSFetchRequest *fetchRequest = [self fetchRequestForGroupId:groupId orderAscending:orderAscending];

    [fetchRequest setFetchLimit:0];
    [fetchRequest setIncludesPendingChanges:NO];
    return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestForAllWithOrderAscending:(BOOL)orderAscending
{
    NSFetchRequest *fetchRequest = [WovenPhoto fetchRequest];
    [fetchRequest setSortDescriptors:[WovenPhoto wovenPhotoSortDescriptorsAscending:orderAscending]];

    // For the All Photos group, skip photos with the flag 'skipForTimeline'
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:
                                @"(%K != %@) AND (%K != %@)",
                                kWovenSkipForTimeLineKey, @YES, kWovenIsPhotoDeletedKey, @YES]];

    return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestForGroupId:(NSString *)groupId orderAscending:(BOOL)orderAscending
{
    if (!groupId) {
        return nil;
    }

    NSFetchRequest *fetchRequest = [WovenPhoto fetchRequest];
    [fetchRequest setSortDescriptors:[WovenPhoto wovenPhotoSortDescriptorsAscending:orderAscending]];

    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:
                                @"(%K != %@) AND %K CONTAINS %@",
                                kWovenIsPhotoDeletedKey, @YES,
                                kWovenGroupIdsKey, groupId]];

    return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestForGroup:(WovenGroup *)group orderAscending:(BOOL)orderAscending
{
    return [self fetchRequestForGroupId:[group groupId] orderAscending:orderAscending];
}

- (NSArray *)groups
{
    NSArray *groupIdArray = [[self groupIds] componentsSeparatedByString:@","];
    NSArray *result = [WovenGroup objectsWithIds:groupIdArray];

    return result;
}

+ (NSArray *)wovenPhotoSortDescriptorsAscending:(BOOL)orderAscending
{
    NSSortDescriptor *date = [NSSortDescriptor sortDescriptorWithKey:kWovenDateKey ascending:orderAscending];
    NSSortDescriptor *photoId = [NSSortDescriptor sortDescriptorWithKey:kWovenPhotoIdKey ascending:orderAscending];

    // sorts by date then (if they are both same) photoId which is always unique
    return @[date, photoId];
}

+ (NSNumber *)numberOfPhotosWithSourceId:(NSString *)sourceId
{
    static NSPredicate *tempPredicate = nil;
    if (!tempPredicate) {
        tempPredicate = [[NSPredicate predicateWithFormat: @"%K != YES AND %K == $ID",
                          kWovenIsPhotoDeletedKey, kWovenSourceIdKey] retain];
    }

    NSPredicate *predicate = [tempPredicate predicateWithSubstitutionVariables:@{@"ID": sourceId}];
    return [self numberOfEntitiesWithPredicate:predicate];
}

- (NSString *)description
{
    return [NSString stringWithFormat:
            @"<%@ photoId:%@, rid:%@, title:%@, sourceType:%@, sourceId:%@, groupIds:%@, date:%@, "
            "photoURL:%@, isPhotoDeleted:%@>",
            [self class], [self photoId], [self rid], [self title], [self sourceType], [self sourceId],
            [self groupIds], [self date], [self photoURL], [self isPhotoDeleted]
            ];
}

+ (NSArray *)photosWithGroupId:(NSString *)groupId
{
    return [self objectsWithPredicate:[NSPredicate predicateWithFormat:
                                       @"(%K != %@) AND %K CONTAINS %@",
                                       kWovenIsPhotoDeletedKey, @YES,
                                       kWovenGroupIdsKey, groupId]];
}

+ (NSArray *)allPhotosOldestToNewest
{
    if (![self managedObjectContext]) {
        return nil;
    }

    NSFetchRequest *fetchRequest = [WovenPhoto fetchRequest];
    [fetchRequest setSortDescriptors:[WovenPhoto wovenPhotoSortDescriptorsAscending:YES]];

    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:
                                @"(%K != %@) AND (%K != %@)",
                                kWovenSkipForTimeLineKey, @YES, kWovenIsPhotoDeletedKey, @YES]];

    return [self objectsWithFetchRequest:fetchRequest];
}

- (BOOL)addGroupId:(NSString *)groupId
{
    return [self change:ADD groupId:groupId];
}

- (BOOL)removeGroupId:(NSString *)groupId
{
    return [self change:REMOVE groupId:groupId];
}

- (BOOL)change:(BOOL)adding groupId:(NSString *)groupId
{
    if (!groupId) {
        return NO;
    }

    NSString *groupList = [self groupIds];
    NSMutableArray *groupArray = [NSMutableArray arrayWithArray:[groupList componentsSeparatedByString:@","]];

    NSInteger index = [groupArray indexOfObject:groupId];

    if (adding) {
        if (index < [groupArray count]) {
            return NO; // groupId is already present, don't add again!
        }

        [groupArray addObject:groupId];
    } else if (index < [groupArray count]) {
        [groupArray removeObjectAtIndex:index];
    }

    groupList = [groupArray componentsJoinedByString:@","];
    [self setGroupIds:groupList];

    return YES;
}

@end
