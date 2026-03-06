# Package Introduction

This package provides a set of widgets used for dashboard. Its APIs and architecture are very similar to `GridView` and `SliverGrid` in Flutter, but has different layout logic (delegates to `DashboardPOsitioner` under `lib/src/classes/layout_positioner.dart` which support positioning items in different rows/columns)


However, the resize/dragging logics are still under development. I proposed `ResizableItemWidget` and interface `DashboardResizer` to handle resize logics, but the implementation is not complete yet and I am not sure if this is the best way to implement it.

Here are you goals for this task:

## Task 1: Support resizing items in the dashboard

1. If the item can be resized in the range of its min/max size, if min/max is not given, it can be resized to any size as long as it does not blocked by other items.
2. If resizing will collide with other items along the `ResizeDirection`, the other items should also shrink to make room for the resizing item item, BUT the other items should not shrink smaller than their min size, if any. (No need to expand other items back if the resize direction is reversed)
3. When resizing (either expanding/shrinking an item), a placeholder item should be shown (typically a background painter) to indicate the potential new position and size of the item.
4. When the resizing is confirmed, the focused item should be placed in the position of the placeholder. 


1. If an item has no min/max range, it cannot be resized smaller than its current size, but can be resized larger as long as it does not blocked by other items.
2. If resizing will collide with other items along the `ResizeDirection`, the other items should also shrink to make room for the resizing item item, BUT the other items should not shrink smaller than their min size, if any. (No need to expand other items back if the resize direction is reversed, or the resize operation is cancelled)
3. Implement this logic in `lib/src/classes/resize_drag.dart`. You could refer to `lib/src/classes/drags.dart` and `lib/src/classes/move_drag.dart` for the dragging logic.