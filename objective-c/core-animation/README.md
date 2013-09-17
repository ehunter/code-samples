Core Animation Example
============

This is a brief example showing a UITableCellView animating in with Core Animation. 

The animation performs a 3D transform on the layer to give the effect that the
view is subtly flipping into position.

The cell's TableViewController initiates an animation like so: 

```
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell
                                         forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [(AnimatedTableCellView *)cell flipImageInWithDuration:0.35 andDelay:delay];
    delay += 0.1;
    initialAnimationCount++;
}
```

This is code I wrote specifically for the app I currently work on called Woven during
an exploration phase for animations. We ended up not using this animation, but I learned
a lot about core animation in the process.