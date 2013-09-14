/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "MemoryLaneKit/MemoryLaneKit.h"
#import "UIViewController.h"

/*
GridUpdateStatePaused:  If the grid is in a paused state the results controller won't update
                            anything visually but it will keep it's data in tact. Mainly used when the grid is
                            in an 'edit mode', i.e. action mode.

GridUpdateStateStopped: Releases/nils out our resultsController and delegate making sure the grid
                            dumps it's data and doesn't update visually.

GridUpdateStateResume:  Creates results controller if we don't have one. Reloads the grid's data either way.

GridUpdateStateChanged: Re-creates results controller and reloads the grid.
*/

typedef enum {
    WovenGridUpdateStatePaused,
    WovenGridUpdateStateResume,
    WovenGridUpdateStateChanged,
    WovenGridUpdateStateStopped
} WovenGridUpdateState;

extern NSString * const kAllPhotosGroupId;

@protocol WovenGridViewDelegate;

@interface GridController : UIViewController <UICollectionViewDelegate, WovenObjectStoreDelegate>

@property (nonatomic) WovenGridUpdateState updateState;
@property (readwrite, assign) id<WovenGridViewDelegate> delegate;
@property (nonatomic, copy) NSString *groupId;
@property (nonatomic, readonly, retain) UICollectionView *gridView;
@property (readwrite) BOOL orderGridAscending;
@property (readonly) NSUInteger topItemIndex;

- (void)refreshResultsController:(BOOL)reloadData;
- (void)refreshCellSelectionsForTV;
- (void)resetSelectedCellIndexes;
- (void)scrollToPosition:(CGPoint)point animated:(BOOL)animated;
- (void)scrollToBottomAnimated:(BOOL)animated;
- (void)selectPhotoAtIndex:(NSUInteger)index;
- (void)updateScrollPositionIfNecessary:(NSUInteger)index;
- (WovenPhoto *)wovenPhotoAtIndex:(NSUInteger)index;
- (NSInteger)indexOfPhotoId:(NSString *)photoId;
- (NSUInteger)photoCount;

@end

@protocol WovenGridViewDelegate <NSObject>

- (void)wovenGridHandleRemoveLastPhoto;

@optional
- (void)wovenGridController:(WovenGridController *)gridController setDateForScrollBarHandleAccessory:(NSDate *)date;
- (void)wovenGridView:(UICollectionView *)gridView willSelectItem:(id)item atIndex:(NSUInteger)index;
- (void)wovenGridView:(UICollectionView *)gridView didSelectItem:(id)item atIndex:(NSUInteger)index;

@end
