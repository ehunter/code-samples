/* Copyright 2013 litl, LLC. All Rights Reserved. */

#import "MicroeventManager.h"
#import "NSDate+LitlUtility.h"
#import <MemoryLaneKit/MemoryLaneKit.h>
#import "UserDefaultsManager.h"

NSString * const kMicroeventCreationComplete = @"kMicroeventCreationComplete";
NSString * const kMicroeventPath = @"MicroeventDir";
NSString * const kDeletedMicroevents = @"DeletedMicroevents";
NSTimeInterval const kDefaultMicroeventMinutes = 30;
#define SCENE_THRESHOLD 200
#define WIGGLE_MIN 3

@interface MicroeventManager ()
{
    MLWovenObjectStore *objectStore;
    NSUInteger sceneCount;
    NSMutableOrderedSet *tempWigglePhotos;
}

@property (nonatomic, retain) NSMutableArray *deletedMicroeventIds;
@property (nonatomic) BOOL isCanceled;

@end

@implementation MicroeventManager

- (id)init
{
    if ((self = [super init])) {
        objectStore = (id)[[WovenClient sharedObjectStore] retain];
         [self litl_notifyMe:kMicroeventCreationComplete selector:@selector(handleMicroeventsCreationComplete)];
        tempWigglePhotos = [[NSMutableOrderedSet alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [objectStore release];
    [_deletedMicroeventIds release];
    [tempWigglePhotos release];
    [super dealloc];
}

- (void)createEvents
{
    if (!_isRunning) {
        _isRunning = YES;
        _isCanceled = NO;
        [self performSelectorInBackground:@selector(createEventsInBackground) withObject:nil];
    }
}

- (void)handleMicroeventsCreationComplete
{
    _isRunning = NO;
    _isCanceled = NO;
}

- (void)cancelEventCreation
{
     _isCanceled = YES;
}

- (NSUInteger)microeventIntervalMinutes
{
    NSUInteger interval = [[App userDefaultsManager] microeventIntervalMinutes];
    return interval ? : kDefaultMicroeventMinutes;
}

- (void)setMicroeventIntervalMinutes:(NSUInteger)value
{
    [[App userDefaultsManager] setMicroeventIntervalMinutes:value];
}

- (NSUInteger)microeventCount
{
    return [[WovenGroup allMicroevents] count];
}

- (void)createEventsInBackground
{
    /*
     In short: sort the photos by date/time, and consider each pair of consecutive photos.
     If they're taken within 30 minutes of each other, they are in the same microevent.
     These chain together: any time you see more than a 30 minute gap, you can close the current microevent.
     */
    NSArray *allPhotos = [WovenPhoto allPhotosOldestToNewest];

    if (![allPhotos count]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMicroeventCreationComplete object:nil];
        });
        return;
    }

    // Photos we share are immediately re-synced and a sync wipes out our local group id in the photo managedObject!
    // So we need to remake all microevents after any sync. Remaking, in turn, recreates any deleted events,
    // so we need to save a list of deleted groups and skip remaking those.

    [self readDeletedMicroeventsFromDisk];

    NSTimeInterval microEventSize = [self microeventIntervalMinutes] * 60;
    DDLogVerbose(@"MicroeventsManager using microEventSize=%f",microEventSize);

    NSUInteger start = 0;
    WovenPhoto *prevPhoto = allPhotos[start];
    NSTimeInterval eventEndsDate = [[prevPhoto date] timeIntervalSince1970] + microEventSize;

    WovenGroup *event = nil;

    @autoreleasepool {
        for (NSUInteger i = start+1; i < [allPhotos count]; i++) {

            if (_isCanceled) {
                break;
            }

            WovenPhoto *currentPhoto = allPhotos[i];

            if ([[currentPhoto date] timeIntervalSince1970] <= eventEndsDate) {
                if (!event) {
                    event = [self nilOrMicroeventWithPhoto:prevPhoto
                                                    withId:[prevPhoto photoId]
                                                 groupType:WovenGroupTypeLocalMicroevent
                                             groupTypeName:kWovenGroupTypeNameMicroevent];
                    if (event) {
                        [prevPhoto addGroupId:[event groupId]]; // addGroupId doesn't add duplicates
                    }
                }

                if (event) {
                    [currentPhoto addGroupId:[event groupId]];
                }

                [currentPhoto setVisualDiff:[self visualDiffForPhoto:currentPhoto comparedToPhoto:prevPhoto]];
                [self comparePhotosForWiggle:currentPhoto prevPhoto:prevPhoto];
            } else if (event) {
                [objectStore save];
                event = nil;
                [self resetWiggleData];
            }

            prevPhoto = currentPhoto;
            eventEndsDate = [[currentPhoto date] timeIntervalSince1970] + microEventSize;
        }
    }
    [objectStore save];

    [self resetWiggleData];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kMicroeventCreationComplete object:nil];
    });
}

- (WovenGroup *)nilOrMicroeventWithPhoto:(WovenPhoto *)photo
                                   withId:(NSString *)newId
                               groupType:(WovenGroupType)groupType
                           groupTypeName:(NSString *)groupTypeName

{
    NSUInteger index = [_deletedMicroeventIds indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ([(NSString *)obj isEqualToString:newId]);
    }];

    if (index != NSNotFound) {
        // we previously deleted this group, skip it
        return nil;
    }

    if (!newId) {
        return nil;
    }
    WovenGroup *newGroup = (WovenGroup *)[objectStore findOrCreateInstanceOfEntity:[WovenGroup entity]
                                                           withPrimaryKeyAttribute:[WovenGroup primaryKey]
                                                                          andValue:newId];

    [newGroup setGroupTypeName:groupTypeName];
    [newGroup setGroupType:@(groupType)];
    [newGroup setSourceType:kWovenGroupSourceTypeIOS];
    [newGroup setSortField:kWovenGroupSortFieldOldestToNewest];
    [newGroup setIsGroupDeleted:@(NO)];
    [newGroup setDate:[photo date]];
    [newGroup setGroupId:newId];

    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    }

    [newGroup setTitle:[dateFormatter stringFromDate:[photo date]]];

    return newGroup;
}

- (NSString *)microeventsDirectoryName
{
    NSArray *cachesPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [cachesPaths[0] stringByAppendingPathComponent:kMicroeventPath];
}

- (NSString *)deletedMicroeventsFileName
{
    return [[self microeventsDirectoryName] stringByAppendingPathComponent:kDeletedMicroevents];
}

- (void)reset
{
    [[NSFileManager defaultManager] removeItemAtPath:[self microeventsDirectoryName] error:nil];

    for (NSManagedObject *group in [WovenGroup allMicroevents]) {
            [objectStore deleteObject:group];
    }

    [objectStore save];
}

- (void)removeMicroeventWithId:(NSString *)groupId
{
    WovenGroup *group = (WovenGroup *)[objectStore findOrCreateInstanceOfEntity:[WovenGroup entity]
                                                        withPrimaryKeyAttribute:[WovenGroup primaryKey]
                                                                       andValue:groupId];
    if (group) {
        [objectStore deleteObject:group];
        [objectStore save];
        [self saveDeletedMicroeventIdToDisk:groupId];
    }
}

- (void)saveDeletedMicroeventIdToDisk:(NSString *)groupId
{
    // I know its slow, but prototyping and there is an enumerator in actionManager that drives
    // this one at a time that makes it too much to change for the moment.
    [self readDeletedMicroeventsFromDisk];
    [_deletedMicroeventIds addObject:groupId];
    [_deletedMicroeventIds writeToFile:[self deletedMicroeventsFileName] atomically:YES];
}

- (void)readDeletedMicroeventsFromDisk
{
    NSString *microeventsPath = [self microeventsDirectoryName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:microeventsPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:microeventsPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }

    NSArray *array = [NSArray arrayWithContentsOfFile:[self deletedMicroeventsFileName]];

    [_deletedMicroeventIds release];
    _deletedMicroeventIds = array ? [array mutableCopy] : [[NSMutableArray alloc] init];
}

- (NSNumber *)visualDiffForPhoto:(WovenPhoto *)currentPhoto comparedToPhoto:(WovenPhoto *)prevPhoto
{
    // the thumbIds are an 8x8x3 matrix of lab color space chars for each photo.
    // in the protobuf parsing we put them in a comma separated string
    NSArray *prevIds = [[prevPhoto thumbIds] componentsSeparatedByString:@","];
    NSArray *currIds = [[currentPhoto thumbIds] componentsSeparatedByString:@","];

    NSUInteger sum = 0;
    // the euclidean distances between each point in the array determines the similarity of one photo to another.
    // we determine the difference by calculating the square root of the sum of the squared distances between
    // each value in the two arrays.

    // first get the sum of the squared differences for each corresponding point
    for (int i = 0; i < [prevIds count]; i++) {
        sum += pow(abs([[prevIds objectAtIndex:i] integerValue] - [[currIds objectAtIndex:i] integerValue]), 2);
    }

    // now return the square root of that sum
    return [NSNumber numberWithFloat:sqrt(sum)];
}

- (void)comparePhotosForWiggle:(WovenPhoto *)currentPhoto prevPhoto:(WovenPhoto *)prevPhoto
{
    float thumbDiff = [[currentPhoto visualDiff] floatValue];

    if (thumbDiff > 0 && thumbDiff <= SCENE_THRESHOLD) {
        if (![prevPhoto wiggleId]) {
            // generate a UUID for this scene
            CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
            [prevPhoto setWiggleId:(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid)];
            CFRelease (uuid);
        }
        // since this is an orderedSet duplicates won't get added
        [tempWigglePhotos addObject:currentPhoto];
        [tempWigglePhotos addObject:prevPhoto];

        sceneCount += 1;
    } else {
        // only create a 'wiggle' if we've added more than 3 photos to the set
        if ([tempWigglePhotos count] >= WIGGLE_MIN) {
            WovenPhoto *firstPhoto = [tempWigglePhotos objectAtIndex:0];
            WovenGroup *event = [self nilOrMicroeventWithPhoto:firstPhoto
                                                        withId:[firstPhoto wiggleId]
                                                     groupType:WovenGroupTypeLocalWiggle
                                                 groupTypeName:kWovenGroupTypeNameWiggle];

            DDLogVerbose(@"Created wiggle with %i photos", [tempWigglePhotos count]);

            if (event) {
                for (WovenPhoto *photo in tempWigglePhotos) {
                    [photo addGroupId:[firstPhoto wiggleId]];
                    [photo setWiggleId:[firstPhoto wiggleId]];
                }
            }
        } else if ([tempWigglePhotos count]) {
            // reset the sceneId for the photos that were similar but didn't meet the minimum
            for (WovenPhoto *photo in tempWigglePhotos) {
                [photo setWiggleId:nil];
            }
        }

        [self resetWiggleData];
    }
}

- (void)resetWiggleData
{
    [tempWigglePhotos removeAllObjects];
    sceneCount = 0;
}

@end
