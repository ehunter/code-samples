/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "WovenGroup.h"
#import "WovenClient.h"
#import "WovenAccountManager.h"

#pragma mark - constants

NSString * const kWovenGroupIdKey = @"groupId";
NSString * const kWovenGroupTypeKey = @"groupType";
NSString * const kWovenIsGroupDeletedKey = @"isGroupDeleted";
NSString * const kWovenGroupSourceTypeKey = @"sourceType";
NSString * const kWovenGroupSourceIdKey = @"sourceId";
NSString * const kWovenGroupTitleKey = @"title";

NSString * const kWovenGroupTypeNameAlbum = @"album";
NSString * const kWovenGroupTypeNameSource = @"source";
NSString * const kWovenGroupTypeNameUser = @"user";
NSString * const kWovenGroupTypeNameMicroevent = @"microevent";
NSString * const kWovenGroupTypeNameWiggle = @"wiggle";
NSString * const kWovenGroupTypeNameWordgroup = @"wordgroup";
NSString * const kWovenGroupTypeNameShare = @"share";

NSString * const kWovenGroupSortFieldOldestToNewest = @"ctime";
NSString * const kWovenGroupSortFieldNewestToOldest = @"-ctime";

NSString * const kWovenGroupSourceTypeIOS = @"ios";

#pragma mark - WovenGroup

@implementation WovenGroup

@dynamic groupId;
@dynamic title;
@dynamic sourceType;
@dynamic date;
@dynamic coverSizes;
@dynamic coverPhoto;
@dynamic sourceId;
@dynamic groupType;
@dynamic groupTypeName;
@dynamic isGroupDeleted;
@dynamic sortField;
@dynamic rid;

+ (NSString *)primaryKey
{
    return kWovenGroupIdKey;
}

+ (NSFetchRequest *)fetchRequestForAll
{
    NSFetchRequest *fetchRequest = [WovenGroup fetchRequest];
    NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:kWovenDateKey ascending:NO];
    NSSortDescriptor *idSort = [NSSortDescriptor sortDescriptorWithKey:kWovenGroupIdKey ascending:NO];
    [fetchRequest setSortDescriptors:@[dateSort, idSort]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:
                                @"(%K == %@) AND (%K != %@)",
                                kWovenGroupTypeKey, @(WovenGroupTypeAlbum), kWovenIsGroupDeletedKey, @YES]];
    [fetchRequest setIncludesPendingChanges:NO];
    return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestForAllMicroevents
{
    NSFetchRequest *fetchRequest = [WovenGroup fetchRequest];
    NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:kWovenDateKey ascending:NO];
    [fetchRequest setSortDescriptors:@[dateSort]];
    [fetchRequest setPredicate:[self predicateForAllMicroevents]];
    [fetchRequest setIncludesPendingChanges:NO];
    return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestForAllWiggles
{
    NSFetchRequest *fetchRequest = [WovenGroup fetchRequest];
    NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:kWovenDateKey ascending:NO];
    [fetchRequest setSortDescriptors:@[dateSort]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:
                                @"(%K == %@) AND (%K != %@)",
                                kWovenGroupTypeKey, @(WovenGroupTypeLocalWiggle),
                                kWovenIsGroupDeletedKey, @YES]];
    [fetchRequest setIncludesPendingChanges:NO];
    return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestForAllMicroeventsAndWiggles
{
    NSFetchRequest *fetchRequest = [WovenGroup fetchRequest];
    NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:kWovenDateKey ascending:NO];
    [fetchRequest setSortDescriptors:@[dateSort]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:
                                @"(%K == %@) OR (%K == %@) AND (%K != %@)",
                                kWovenGroupTypeKey, @(WovenGroupTypeLocalMicroevent),
                                kWovenGroupTypeKey, @(WovenGroupTypeLocalWiggle),
                                kWovenIsGroupDeletedKey, @YES]];
    [fetchRequest setIncludesPendingChanges:NO];
    return fetchRequest;
}

+ (NSArray *)allMicroevents
{
    return [self objectsWithPredicate:[self predicateForAllMicroevents]];
}

+ (NSPredicate *)predicateForAllMicroevents
{
    return [NSPredicate predicateWithFormat:@"(%K == %@) AND (%K != %@)", kWovenGroupTypeKey,
                                            @(WovenGroupTypeLocalMicroevent), kWovenIsGroupDeletedKey, @YES];
}

+ (NSFetchRequest *)fetchRequestForGroupId:(NSString *)groupId
{
    NSFetchRequest *fetchRequest = [WovenGroup fetchRequest];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:kWovenDateKey ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@",
                                kWovenGroupIdKey, groupId]];

    return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestForSourceId:(NSString *)sourceId
{
    NSFetchRequest *fetchRequest = [WovenGroup fetchRequest];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:kWovenDateKey ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    [fetchRequest setIncludesPendingChanges:NO];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:
                                @"%K == %@ AND (%K == %@) AND (%K != %@)",
                                kWovenSourceIdKey, sourceId,
                                kWovenGroupTypeKey, @(WovenGroupTypeAlbum), kWovenIsGroupDeletedKey, @YES]];
    return fetchRequest;
}

- (NSSet *)coverPhotoSizes
{
    if ([[self coverSizes] count] == 0) {
        return [[self coverPhoto] sizes];
    }
    return [self coverSizes];
}

- (NSString *)albumTitle
{
    if ([[self sourceType] isEqualToString:kWovenGroupSourceTypeIOS]) {
        WovenAccountManager *accountManager = [[WovenClient sharedClient] accountManager];
        NSString *loginName = [accountManager accountLoginNameForAccountId:[self sourceId]];
        NSString *title = [NSString stringWithFormat:LocStr(@"album_title_format"), [self title], loginName];
        return loginName ? title : [self title];
    }

    return [self title];
}

+ (NSArray *)groupsMatchingDeviceAlbumName:(NSString *)name
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@",
                              kWovenGroupSourceTypeKey, kWovenGroupSourceTypeIOS,
                              kWovenGroupTitleKey, name];
    return [self objectsWithPredicate:predicate];
}

+ (NSNumber *)numberOfGroupsWithSourceId:(NSString *)sourceId
{
    static NSPredicate *tempPredicate = nil;
    if (!tempPredicate) {
        tempPredicate = [[NSPredicate predicateWithFormat: @"%K != YES AND %K == $ID",
                         kWovenIsGroupDeletedKey, kWovenGroupSourceIdKey] retain];
    }

    return [self numberOfEntitiesWithPredicate:[tempPredicate predicateWithSubstitutionVariables:
                                                @{@"ID": sourceId}]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:
            @"<%@ groupId:%@, rid:%@, title:%@, sourceType:%@, sourceId:%@, date:%@, "
            "groupType:%@, groupTypeName:%@, isGroupDeleted:%@, sortField:%@>",
            [self class], [self groupId], [self rid], [self title], [self sourceType], [self sourceId], [self date],
            [self groupType], [self groupTypeName], [self isGroupDeleted], [self sortField]
            ];
}


@end
