/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "GridController.h"
#import "GridViewCell.h"
#import "ExternalDisplayManager.h"
#import "SyncManager.h"
#import "WebImageManager.h"
#import "ActionManager.h"
#import "GridViewFlowLayout.h"
#import "UIViewController+LitlUtility.h"
#import "NSMutableDictionary+LitlUtility.h"
#import "UIManager.h"
#import <MemoryLaneKit/WovenURLConstructor.h>

#pragma mark - GridScrollPosition

// Used to store the scroll position of each gallery, per groupId.
//
// One might wonder why not store this as an absolute offset on the UIScrollView. This is b/c the absolute offset for
// different orientations would be different. The inner workings of UICollectionView does not store the content offset
// after invalidating the layout, so we must save it ourselves. (We must invalidate the layout when changes in our
// view take place because our grid cells are different sizes depending on orientation. Invalidating the layout
// forces a redraw of the grid cells).

@interface GridScrollPosition : NSObject

@property (nonatomic) NSUInteger index;
@property (nonatomic) CGFloat proportionalYOffset;
@property (nonatomic) UIInterfaceOrientation savedOrientation;

@end

@implementation GridScrollPosition

@end

#pragma mark - GridController

#define UPDATE_BATCH_SIZE_SMALL 50
#define UPDATE_BATCH_SIZE_MED 100
#define UPDATE_BATCH_SIZE_LARGE 500
#define PADDING (IsPad() ? 12 : 6)
#define POSITION_DATA_PER_GROUP_ID @"GridContoller.positionDataPerGroupId"
#define SCROLL_POSITION_KEY @"scrollPosition"
#define PREVIOUSLY_VISIBLE_INDEX_PATHS_KEY @"indexPaths"

NSString * const kAllPhotosGroupId = @"allPhotosGroup";
NSString * const kCellIdentifier = @"CollectionViewCellIdentifier";


@interface GridController () <NSFetchedResultsControllerDelegate,
                                   UICollectionViewDataSource>
{
    NSFetchedResultsController *resultsController;
    NSOperationQueuePriority priority;
    NSInteger currentlySelectedIndex;
    NSInteger previouslySelectedIndex;
    CGPoint gridOffset;
    CGSize oldGridSize;
    NSUInteger totalGridItems;
    NSUInteger rowsPerPage;
    NSUInteger columnsPerPage;
    BOOL wasAtBottom;
    BOOL doScrollToPrevious;
    NSUInteger refreshBatchSize;
}

// Position data is per user, and lives in [App transientUserData]. When the user changes or the app
// terminates, user data will automatically disappear.
//
// [App transientUserData][POSITION_DATA_PER_GROUP_ID] =
//  @{@"groupId1" : @{ @"scrollPosition" : scrollPosition,
//                     @"indexPaths"     : previouslyVisibleIndexPaths},
//     etc. }
//
// NOTE: the retained properties are retained by the backing transientUserData dict, not in-object.
// However, semantically, retain is correct.

@property (readonly) NSMutableDictionary *positionUserData;
@property (nonatomic, retain) GridScrollPosition *scrollPosition;
@property (nonatomic, retain) NSArray *previouslyVisibleIndexPaths;

@end

@implementation GridController

- (id)init
{
    if ((self = [super init])) {
        priority = NSOperationQueuePriorityHigh;

        refreshBatchSize = UPDATE_BATCH_SIZE_LARGE;
        [self resetSelectedCellIndexes];

        GridViewFlowLayout *gridViewFlowLayout = [[GridViewFlowLayout alloc] init];

        [gridViewFlowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        [gridViewFlowLayout setMinimumInteritemSpacing:PADDING];
        [gridViewFlowLayout setMinimumLineSpacing:PADDING];
        [gridViewFlowLayout setSectionInset:UIEdgeInsetsMake(PADDING, PADDING, PADDING, PADDING)];

        _gridView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:gridViewFlowLayout];

        [_gridView setDelegate:self];
        [_gridView setDataSource:self];
        [_gridView registerClass:[GridViewCell class] forCellWithReuseIdentifier:kCellIdentifier];
        [_gridView setAutoresizingMask:UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin];

        [_gridView setBackgroundColor:[UIColor clearColor]];
        [_gridView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];

        [gridViewFlowLayout release];

        [(MLWovenObjectStore *)[WovenClient sharedObjectStore] addChangeDelegateForClass:[WovenPhoto class]
                                                                                delegate:self];
        // by default set the update state to always update
        [self setUpdateState:GridUpdateStateResume];
    }

    return self;
}

- (void)loadView
{
    [super loadView];

    [self setView:_gridView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];

    [self resetSelectedCellIndexes];
    [self initiateNotifications];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[_gridView collectionViewLayout] invalidateLayout];

    // This holds state required below; something between here and the "if (rezero)" below
    // unintentinally nudges contentOffset by a pixel or two sometimes (probably updateViewFrames...).
    if (CGPointEqualToPoint([_gridView contentOffset], CGPointZero)) {
        [_gridView setContentOffset:CGPointZero];
    }

    doScrollToPrevious = YES;
}

- (void)viewWillLayoutSubviews
{
    // scroll to previous offset, if applicable
    if (doScrollToPrevious && [[self view] bounds].size.width > 0 && [[self view] bounds].size.height > 0) {
        doScrollToPrevious = NO;

        GridScrollPosition *scrollPos = [self scrollPosition];

        if (scrollPos) {
            UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            CGFloat newYOffset = [_gridView bounds].size.height * [scrollPos proportionalYOffset];
            // if the orientation has changed or the index was not previously visible snap to the photo
            if (!isnan([scrollPos index]) && ([scrollPos savedOrientation] != currentOrientation ||
                                              ![self wasIndexVisible:[scrollPos index]])) {
                [self selectPhotoAtIndex:[scrollPos index]];
                [self updatePreviouslyVisibleIndexes];
            } else if (!isnan(newYOffset)) {
                [_gridView setContentOffset:CGPointMake(_gridView.contentOffset.x, newYOffset)];
            }
        }
    }

    [super viewWillLayoutSubviews];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    wasAtBottom = [self isGridAtBottom];

    if (![[App UIManager] isSigningOut]) {
        [self updateScrollPositionForGroupId];
        [self updatePreviouslyVisibleIndexes];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [[_gridView collectionViewLayout] invalidateLayout];

    gridOffset = [_gridView contentOffset];
    oldGridSize = [_gridView contentSize];
    wasAtBottom = [self isGridAtBottom];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGSize newGridSize = [_gridView contentSize];

    if (wasAtBottom && (newGridSize.height > [_gridView bounds].size.height)) {
        [self scrollToBottomAnimated:NO];
    } else if (gridOffset.y > 0 && oldGridSize.height > (PADDING * 2)) {
        CGFloat proportionalY = newGridSize.height * (gridOffset.y / oldGridSize.height);
        NSIndexPath *index = [_gridView indexPathForItemAtPoint:CGPointMake(PADDING, proportionalY)];
        // UICollectionView won't return a valid index for a point where there is just padding
        if (!index) {
            index = [_gridView indexPathForItemAtPoint:CGPointMake(PADDING, proportionalY - PADDING)];
        }

        CGRect cellRect = [[self collectionView:_gridView cellForItemAtIndexPath:index] frame];
        CGFloat newY = proportionalY;

        if (cellRect.origin.y > 0) {
            newY = (proportionalY < (cellRect.origin.y + (cellRect.size.height / 2.0f))) ?
            cellRect.origin.y - PADDING : cellRect.origin.y + cellRect.size.height;
        }

        [_gridView setContentOffset:CGPointMake(_gridView.contentOffset.x, newY)];

        doScrollToPrevious = NO;
    }

    [self updateScrollPositionForGroupId];
    [self updatePreviouslyVisibleIndexes];
}

- (void)dealloc
{
    [_gridView removeObserver:self forKeyPath:@"contentOffset"];
    [resultsController release];
    [_groupId release];
    [_gridView release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

#pragma mark - properties

- (NSUInteger)topItemIndex
{
    NSArray *indices = [_gridView indexPathsForVisibleItems];
    if ([indices count]) {
        CGFloat top = [(NSIndexPath *)indices[0] item];
        for (NSIndexPath *indexPath in indices) {
            CGFloat index = [indexPath item];
            top = (index >= top) ? top : index;
        }
        return top;
    } else {
        return 0;
    }
}

- (void)setUpdateState:(GridUpdateState)updateState
{
    _updateState = updateState;

    // FYI - for a description of what these states do look at the notes in the typedef
    switch (updateState) {
        case GridUpdateStatePaused:
            break;
        case GridUpdateStateResume:
            if (!resultsController) {
                [self refreshResultsController:YES];
            } else {
                [self reloadGrid];
            }
            break;
        case GridUpdateStateChanged:
            [self refreshResultsController:YES];
            break;
        case GridUpdateStateStopped:
            [self refreshResultsController:NO];
            break;
    }
}

// The position data is per user, and lives in [App transientUserData]. When the user changes, previous
// user data will automatically disappear.
//
- (NSMutableDictionary *)positionUserData
{
    if (!_groupId) {
        DDLogError(@"No groupId");
        return nil;
    }

    NSMutableDictionary *transientUserData = [App transientUserData];
    if (!transientUserData) {
        DDLogError(@"No [App transientUserData]");
        return nil;
    }

    NSMutableDictionary *positionUserDataPerGroupId =
     [transientUserData litl_objectForKey:POSITION_DATA_PER_GROUP_ID addIfNotPresent:^id{
         return [NSMutableDictionary dictionary];
     }];

    return [positionUserDataPerGroupId litl_objectForKey:_groupId addIfNotPresent:^id{
        return [NSMutableDictionary dictionary];
    }];
}

- (GridScrollPosition *)scrollPosition
{
    return [self positionUserData][SCROLL_POSITION_KEY];
}

- (void)setScrollPosition:(GridScrollPosition *)scrollPosition
{
    if (scrollPosition) {
        [self positionUserData][SCROLL_POSITION_KEY] = scrollPosition;
    } else {
        [[self positionUserData] removeObjectForKey:SCROLL_POSITION_KEY];
    }
}

- (NSArray *)previouslyVisibleIndexPaths
{
    return [self positionUserData][PREVIOUSLY_VISIBLE_INDEX_PATHS_KEY];
}

- (void)setPreviouslyVisibleIndexPaths:(NSArray *)previouslyVisibleIndexPaths
{
    if (previouslyVisibleIndexPaths) {
        [self positionUserData][PREVIOUSLY_VISIBLE_INDEX_PATHS_KEY] = previouslyVisibleIndexPaths;
    } else {
        [[self positionUserData] removeObjectForKey:PREVIOUSLY_VISIBLE_INDEX_PATHS_KEY];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self numberOfPictures];
}

- (GridViewCell *)collectionView:(UICollectionView *)collectionView
               cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    GridViewCell *newCell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier
                                                                           forIndexPath:indexPath];

    NSUInteger index = [indexPath item];
    [newCell setPhotoURL:[self photoURLAtIndex:index] priority:NSOperationQueuePriorityNormal label:@""];
    [newCell setPhotoId:[[self wovenPhotoAtIndex:index] photoId]];
    [newCell showVideoLabel:[self isVideoAtIndex:index] duration:[self videoDurationAtIndex:index]];

    [[App actionManager] showOrHideOverlayOnView:[newCell contentView] atIndex:[indexPath item]];

    return newCell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewFlowLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    float frameWidth = [_gridView frame].size.width;
    float frameHeight = [self litl_viewHeightWhenUsedInNavigationController];

    // Currently Our grid breaks down like this:
    //   iPad - Portait 3 x 4 : Landscape 4 x 3
    //   iPhone <= 4 - Portait 2 x 3 : Landscape 3 x 2
    //   iPhone 5 aka longPhone - Portrait 2 x 4 : Landscape 4 x 2
    //   Landscape is always Portrait ratio flipped

    rowsPerPage = (IsLandscape() ? (IsPad() ? 3 : 2) : (IsPad() ? 4 : (IsLongPhone() ? 4 : 3)));
    columnsPerPage = (IsLandscape() ? (IsPad() ? 4 : (IsLongPhone() ? 4 : 3)) : (IsPad() ? 3 : 2));

    CGFloat width = (frameWidth - (PADDING * (columnsPerPage + 1))) / columnsPerPage;
    CGFloat height = (frameHeight - (PADDING * (rowsPerPage + 1))) / rowsPerPage;

    return CGSizeMake(width, height);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_delegate respondsToSelector:@selector(GridView:willSelectItem:atIndex:)]) {
        [_delegate GridView:_gridView willSelectItem:[self itemAtIndexPath:indexPath] atIndex:[indexPath item]];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    previouslySelectedIndex = currentlySelectedIndex;
    currentlySelectedIndex = [indexPath item];

    // while display manger is connected, we actually use selection, and
    // shouldn't clear it automatically
    if (![[App externalDisplayManager] isConnected]) {
        [_gridView deselectItemAtIndexPath:indexPath animated:NO];
    } else if (![[App actionManager] inActionMode]) {

        if (previouslySelectedIndex != currentlySelectedIndex) {
            NSIndexPath *previousIndexPath = [NSIndexPath indexPathForItem:previouslySelectedIndex inSection:0];
            GridViewCell *cell = (id)[_gridView cellForItemAtIndexPath:previousIndexPath];
            [cell showTVIconIfNeeded:NO];
        }

        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForItem:currentlySelectedIndex inSection:0];
        GridViewCell *cell = (id)[_gridView cellForItemAtIndexPath:currentIndexPath];
        [cell showTVIconIfNeeded:YES];
    }

    [self updateScrollPositionForGroupId];

    if ([_delegate respondsToSelector:@selector(GridView:didSelectItem:atIndex:)]) {
        [_delegate GridView:_gridView
                   didSelectItem:[self itemAtIndexPath:indexPath]
                         atIndex:currentlySelectedIndex];
    }
}

#pragma mark - WovenObjectStoreProtocol methods

- (void)objectStore:(MLWovenObjectStore *)objectStore didChangeContentForClass:(Class)managedObjectClass
{
    // Don't update anything if we're in a paused state. This is mainly used when the user is in action mode.
    // Actually if we are GridUpdateStatePaused, we've set the RC's delegate to nil and we don't get here
    // at all. But keeping the test here to decouple that dependency
    if (_updateState == GridUpdateStatePaused || _updateState == GridUpdateStateStopped) {
        return;
    }

    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(refetchObjects) withObject:nil waitUntilDone:NO];
        return;
    }

    [self refetchObjects];
}

- (void)refetchObjects
{
    @synchronized(self) {
        [resultsController performFetch:nil];
    }

    [self reloadGrid];
}

#pragma mark - NSFetchedResultsControllerDelegate methods

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // Don't update anything if we're in a paused state. This is mainly used when the user is in action mode.
    // Actually if we are GridUpdateStatePaused, we've set the RC's delegate to nil and we don't get here
    // at all. But keeping the test here to decouple that dependency
    if (_updateState == GridUpdateStatePaused) {
        return;
    }

    // We get a controllerDidChangeContent for every single record added to core data on a sync,
    // but the grid doesn't know about them until it reloads.
    // It's simplest to reload after a refreshBatchSize number of records.
    // The batch size is 50 if we started with an empty grid and reloads at 100 and 500 thereafter.
    // When sync completes we call handleSyncComplete that results in a final reload.
    static int counter = 0;
    counter++;
    if (counter == refreshBatchSize) {
        counter = 0;
        [self reloadGrid];
        refreshBatchSize = (refreshBatchSize == UPDATE_BATCH_SIZE_SMALL) ?
                            UPDATE_BATCH_SIZE_MED : UPDATE_BATCH_SIZE_LARGE;
    }
}

#pragma mark - private methods

- (void)updateScrollPositionForGroupId
{
    GridScrollPosition *gridScrollPosition = [[GridScrollPosition alloc] init];
    [gridScrollPosition setProportionalYOffset:([_gridView contentOffset].y / [_gridView bounds].size.height)];
    [gridScrollPosition setIndex:(currentlySelectedIndex == NSNotFound ? [self topItemIndex] : currentlySelectedIndex)];
    [gridScrollPosition setSavedOrientation:[self interfaceOrientation]];

    [self setScrollPosition:gridScrollPosition];
    [gridScrollPosition release];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    GridViewCell *cell = (id)[_gridView cellForItemAtIndexPath:indexPath];
    // If we have a cell, grab the WovenPhoto from the photoId in the cell, since the
    // underlying resultsController may be changing during a sync.
    if (cell) {
        item = [WovenPhoto objectWithId:[cell photoId]];
    }
    if (!item) {
        // Fall back to what the resultsController thinks the object is.
        item = [resultsController objectAtIndexPath:indexPath];
    }
    return item;
}

- (BOOL)isIndexVisible:(NSUInteger)index
{
    for (NSIndexPath *path in [_gridView indexPathsForVisibleItems]) {
        if (index == [path item]) {
            return YES;
        }
    }

    return NO;
}

// this is used in helping to determine the correct saved content offset for the grid
- (BOOL)wasIndexVisible:(NSUInteger)index
{
    for (NSIndexPath *path in [self previouslyVisibleIndexPaths]) {
        if (index == [path item]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)isGridAtBottom
{
    NSInteger maximumOffset = ([_gridView contentSize].height - [_gridView bounds].size.height);
    return ((maximumOffset - [_gridView contentOffset].y) <= PADDING);
}

- (void)updateCell:(GridViewCell *)cell withIndex:(NSUInteger)index
{
    [cell setPhotoURL:[self photoURLAtIndex:index] priority:NSOperationQueuePriorityNormal label:@""];
    [cell setPhotoId:[[self wovenPhotoAtIndex:index] photoId]];
}

- (NSURL *)photoURLAtIndex:(NSUInteger)index
{
    WovenPhoto *photo = [self wovenPhotoAtIndex:index];

    BOOL isPad = IsPad();
    if (isPad && [[photo gridThumbnailLarge] length]) {
        return [NSURL URLWithString:[photo gridThumbnailLarge]];
    } else if (!isPad && [[photo gridThumbnailSmall] length]) {
        return [NSURL URLWithString:[photo gridThumbnailSmall]];
    }

    CGSize size = [[App webImageManager] gridThumbnailSize];

    return [NSURL URLWithString:[WovenURLConstructor urlFromSizes:[photo sizes] atSize:size allowEnlargement:NO]];
}

- (NSString *)titleAtIndex:(NSUInteger)index
{
    WovenPhoto *photo = [self wovenPhotoAtIndex:index];
    return [photo title];
}

- (NSDate *)dateAtIndex:(NSUInteger)index
{
    WovenPhoto *photo = [self wovenPhotoAtIndex:index];
    return [photo date];
}

- (NSInteger)indexOfPhotoId:(NSString *)photoId
{
    if (!resultsController) {
        return NSNotFound;
    }

    NSInteger index = -1;
    // return the index for the matching photo id, if any
    for(NSUInteger i = 0 ; i < [self numberOfPictures] ; i++){
        if ([[[self wovenPhotoAtIndex:i] photoId] isEqualToString:photoId]) {
            index = i;
            break;
        }
    }
    return index;
}

- (BOOL)isVideoAtIndex:(NSUInteger)index
{
    WovenPhoto *photo = [self wovenPhotoAtIndex:index];
    return [[photo isVideo] boolValue];
}

- (NSNumber *)videoDurationAtIndex:(NSUInteger)index
{
    WovenPhoto *photo = [self wovenPhotoAtIndex:index];
    return [photo videoDuration];
}

- (NSFetchedResultsController *)createResultsControllerForGroupId:(NSString *)groupId
{
    NSFetchRequest *fetchRequest = nil;

    if (![groupId isEqualToString:kAllPhotosGroupId]) {
        WovenGroup *group = [WovenGroup objectWithId:groupId];
        fetchRequest = [WovenPhoto fetchRequestForGroup:group orderAscending:_orderGridAscending];

        if (!fetchRequest) {
            DDLogWarn(@"Group doesn't exist any more, returning nil");
            return nil;
        }
    } else {
        fetchRequest = [WovenPhoto fetchRequestForAllWithOrderAscending:_orderGridAscending];
    }

    [fetchRequest setFetchBatchSize:20];
    return [[WovenClient sharedClient] resultsControllerForFetchRequest:fetchRequest delegate:nil];
}

- (NSUInteger)numberOfPictures
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[resultsController sections] objectAtIndex:0];
    return [sectionInfo numberOfObjects];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object != _gridView || ![keyPath isEqualToString:@"contentOffset"]) {
        return;
    }

    CGSize contentSize = [_gridView contentSize];
    if (contentSize.width == 0 || contentSize.height == 0) {
        return;
    }

    NSArray *indexPaths = [_gridView indexPathsForVisibleItems];

    if (![indexPaths count]) {
        return;
    }

    NSIndexPath *indexPath = indexPaths[0];

    NSDate *date = [self dateAtIndex:[indexPath item]];
    if ([_delegate respondsToSelector:@selector(GridController:setDateForScrollBarHandleAccessory:)]) {
        [_delegate GridController:self setDateForScrollBarHandleAccessory:date];
    }
}

- (void)initiateNotifications
{
    [self litl_notifyMe:kExternalDisplayManagerDidShowPhoto
               selector:@selector(handleExternalDisplayManagerDidShowPhoto)];
    [self litl_notifyMe:kExternalDisplayManagerDidFailToShowPhoto
               selector:@selector(handleExternalDisplayManagerDidFailToShowPhoto)];
    [self litl_notifyMe:kExternalDisplayManagerDidDisconnectAll
               selector:@selector(handleDidDisconnectAllExternalDisplays)];
    [self litl_notifyMe:SYNC_MANAGER_SYNC_COMPLETE_EVENT selector:@selector(handleSyncComplete:)];
    [self litl_notifyMe:WovenResultsControllersNeedRefreshNotification
               selector:@selector(handleResultsControllerNeedsRefresh)];
}

- (void)handleResultsControllerNeedsRefresh
{
    if (_updateState != GridUpdateStatePaused) {
        [self refreshResultsController:(_updateState == GridUpdateStateResume) ? YES : NO];
    }
}

#pragma mark - public methods

- (void)refreshResultsController:(BOOL)reloadData
{
    @synchronized(self) {
        [resultsController setDelegate:nil];
        [resultsController release];
        resultsController = nil;

        if (_groupId && (_updateState == GridUpdateStateResume || _updateState == GridUpdateStateChanged)) {
            resultsController = [[self createResultsControllerForGroupId:_groupId] retain];

            // Pre prune the DB will be removed so the empty grid on sync start problem will go away.
            // But on brand new log in we need to fill the table with blobs as they come,
            // at first it will be empty
            refreshBatchSize = ![self photoCount] ? UPDATE_BATCH_SIZE_SMALL : UPDATE_BATCH_SIZE_LARGE;
            if (reloadData) {
                [self reloadGrid];
            }

            if ([[App externalDisplayManager] isConnected]) {
                [self refreshCellSelectionsForTV];
            }
        }
    }
}

- (void)reloadGrid
{
    [_gridView reloadData];
    [[_gridView collectionViewLayout] invalidateLayout];
}

- (void)resetSelectedCellIndexes
{
    // reset the selected indexes which we use to keep track of
    // the photo currently being viewed on TV
    currentlySelectedIndex = NSNotFound;
    previouslySelectedIndex = NSNotFound;
}

- (void)updatePreviouslyVisibleIndexes
{
    // save the previously visible indexes used in saving the scroll position
    // before getting releasing the results controller which causes indexPathsForVisibleItems to return nil
    if (_gridView) {
        [self setPreviouslyVisibleIndexPaths:[_gridView indexPathsForVisibleItems]];
    }
}

- (WovenPhoto *)wovenPhotoAtIndex:(NSUInteger)index
{
    @synchronized(self) {
        if ([[resultsController fetchedObjects] count] > index) {
            return [resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        } else {
            return nil;
        }
    }
}

- (void)refreshCellSelectionsForTV
{
    NSString *selectedPhotoID = [[App externalDisplayManager] selectedPhotoID];

    // if the currently selected index hasn't been set yet and there's a valid photoID
    if (currentlySelectedIndex == NSNotFound && selectedPhotoID) {
        currentlySelectedIndex = [self indexOfPhotoId:selectedPhotoID];
    }

    // this will automatically deselect previous selection
    if (currentlySelectedIndex == NSNotFound) {
        // Couldn't find photo to select, deselect everything.
        NSArray *items = [_gridView indexPathsForSelectedItems];
        for (NSIndexPath *path in items) {
            [_gridView deselectItemAtIndexPath:path animated:NO];
        }
    } else {
        [_gridView selectItemAtIndexPath:[NSIndexPath indexPathForItem:currentlySelectedIndex inSection:0]
                                animated:NO
                          scrollPosition:UICollectionViewScrollPositionNone];
    }

    // TODO: not sure what good this does now
    previouslySelectedIndex = currentlySelectedIndex;
}

- (void)scrollToPosition:(CGPoint)point animated:(BOOL)animated
{
    [_gridView setContentOffset:point animated:animated];
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    [_gridView setContentOffset:CGPointMake(_gridView.contentOffset.x,
                                            [_gridView contentSize].height - [_gridView bounds].size.height)
                       animated:animated];
}

- (void)selectPhotoAtIndex:(NSUInteger)index
{
    NSUInteger itemsPerPage = rowsPerPage * columnsPerPage;
    doScrollToPrevious = NO;
    currentlySelectedIndex = index;

    // is this index in the bottom set? If not, scroll to it. If so viewDidAppear will handle scrolling to the bottom
    if ((index + 1) <= (totalGridItems - itemsPerPage)) {
        // reset wasAtBottom if we were at the bottom previously but should select an item not in the bottom section
        wasAtBottom = NO;

        @try {
            [_gridView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]
                              atScrollPosition:UICollectionViewScrollPositionTop
                                      animated:NO];
            [_gridView setContentOffset:CGPointMake([_gridView contentOffset].x,
                                                    [_gridView contentOffset].y - PADDING)];

            [self updateScrollPositionForGroupId];
        }
        @catch (NSException *exception) {
            // Fail silently
        }
    }
}

- (void)updateScrollPositionIfNecessary:(NSUInteger)index
{
    doScrollToPrevious = YES;

    // if selected didn't change, then leave alone viewDidLayoutSubviews will handle setting the contentOffset;
    // otherwise check if this index was previously visible. If it wasn't previously visible reset the scroll positon
    if (index != currentlySelectedIndex) {
        // was this in our previously visible set? if so, viewDidLayoutSubviews will set the correct offset.
        if ([self wasIndexVisible:index]) {
            return;
        }
        // nope, not previously visible. Reset the index for the scroll position.
        GridScrollPosition *scrollPos = [self scrollPosition];
        [scrollPos setIndex:index];
    }
}

- (NSUInteger)photoCount
{
    return [[resultsController sections][0] numberOfObjects];
}

#pragma mark ExternalDisplayManager & TVClient notification methods

- (void)handleExternalDisplayManagerDidShowPhoto
{
    [self refreshCellSelectionsForTV];
}

- (void)handleExternalDisplayManagerDidFailToShowPhoto
{
    // TODO should we show an error state if we fail? Alert View?
    if (previouslySelectedIndex != currentlySelectedIndex) {
        currentlySelectedIndex = previouslySelectedIndex;
        previouslySelectedIndex = NSNotFound;
    }
}

- (void)handleDidDisconnectAllExternalDisplays
{
    if (currentlySelectedIndex == NSNotFound || !(currentlySelectedIndex < [self numberOfPictures])) {
        return;
    }

    // NOTE deselectItemAtIndexPath does not seem to fire setSelected:NO when in actionMode
    // so force a refresh of the cell with reloadItemsAtIndexPaths
    NSIndexPath *indexPath= [NSIndexPath indexPathForItem:currentlySelectedIndex inSection:0];
    [_gridView deselectItemAtIndexPath:indexPath animated:NO];
    [_gridView reloadItemsAtIndexPaths:@[indexPath]];
    [self resetSelectedCellIndexes];
}

#pragma mark - SyncHandling methods

- (void)handleSyncComplete:(NSNotification *)notification
{
    if (_updateState != GridUpdateStatePaused) {
        [self refreshResultsController:(_updateState == GridUpdateStateResume) ? YES : NO];
    }
}

@end
