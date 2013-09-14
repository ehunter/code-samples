/* Copyright 2012 litl, LLC. All Rights Reserved. */

#import "GridViewFlowLayout.h"

@implementation GridViewFlowLayout

/*

 This fixes an issue with UICollectionViewFlowLayout when a combination of itemSize, minimumInteritemSpacing and
 sectionInset  exactly matches the width of the UICollectionView and a default vertical scrollDirection
 the layout misplaces the items in the first column. The items are instead placed on the border of the previous
 row as an additional column.

 This was causing cells to sometime disappear from our grid when scrolling up.

 https://openradar.appspot.com/12433891

*/

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *unfilteredPoses = [super layoutAttributesForElementsInRect:rect];
    id filteredPoses[unfilteredPoses.count];
    NSUInteger filteredPosesCount = 0;
    for (UICollectionViewLayoutAttributes *pose in unfilteredPoses) {
        CGRect frame = pose.frame;
        if (frame.origin.x + frame.size.width <= rect.size.width) { // I changed this line
            filteredPoses[filteredPosesCount++] = pose;
        }
    }
    return [NSArray arrayWithObjects:filteredPoses count:filteredPosesCount];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

@end
