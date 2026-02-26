# Package Introduction

This package provides a set of widgets used for dashboard. Its APIs and architecture are very similar to `GridView` and `SliverGrid` in Flutter, but has different layout logic (delegates to `DashboardPOsitioner` under `lib/src/classes/layout_positioner.dart` which support positioning items in different rows/columns)


However, the resize/dragging logics are still under development. I proposed `ResizableItemWidget` and interface `DashboardResizer` to handle resize logics, but the implementation is not complete yet and I am not sure if this is the best way to implement it.

Here are you goals for this task:

## Task 1: Support resizing items in the dashboard

1. If the item can be resized in the range of its min/max size, if min/max is not given, it can be resized to any size as long as it does not blocked by other items.
2. If resizing will collide with other items along the `ResizeDirection`, the other items should also shrink to make room for the resizing item item, BUT the other items should not shrink smaller than their min size, if any. (No need to expand other items back if the resize direction is reversed)
3. When resizing (either expanding/shrinking an item), a placeholder item should be shown (typically a background painter) to indicate the potential new position and size of the item.
4. When the resizing is confirmed, the focused item should be placed in the position of the placeholder. 

## Task2: Support drag and drop to rearrange items in the dashboard

1. When dragging an item, a placeholder (typically a background painter) should be shown to indicate the potential new position of the item. ONLY accepting drop when there is an candidate position (aka. the showing placeholder) for the dragging item.
3. When the dragging is confirmed, the focused item should be placed in the position of the placeholder.
4. Users can set different drag-drop strategies to customize the behavior of find a candidate position for the dragging item
    - Strategy 1: ONLY find empty space that can fit the dragging item, and place the placeholder there. If there is no empty space that can fit the dragging item, the placeholder will not be shown and dropping will not be allowed.
    - Strategy 2: When the dragging item is hovered over other items (if multiple are hovered, the one with the largest hovered area will be selected), the placeholder will be shown in the position of the hovered item, and the hovered item will be temporarily moved to another position that can fit it (similar to how items are rearranged when resizing). If there is no position that can fit the hovered item, it will not be moved and the placeholder will not be shown. In this case, dropping will not be allowed.

In order to decouple the two strategies, you should create 2 delegates for the two strategies,so when users start dragging, delegating the dragging logics to the corresponding delegate based on the selected strategy. You can refer to `DashboardLayoutDelegate` for how to create delegates and use them in the dashboard layout logic.

## Attentions

- For Task 1 and Task 2, if users hit the scroll edge of the dashboard when resizing/dragging, the dashboard should auto scroll in that direction, and the placeholder should also update its position accordingly. You can refer to how `ListView` and `GridView` handle auto scrolling when dragging items in the list/grid for reference.
- As `DashboardView` and `SliverDashboard` are very similar to `GridView`, `SliverGrid`, and `BoxScrollView` in Flutter, so you can refer to the source code of these widgets in Flutter to see how they are implemented, and try to follow the same pattern and architecture when implementing the resize and drag-drop logics. 
- You can refer to `ReorderableListView` in Flutter for reference when implementing the drag-drop logic, as it has some similar features with what we want to achieve in Task 2.
- You can refer to `AnimatedList` and `AnimatedGrid` in Flutter for reference when implementing the placeholder and animation logic when resizing and dragging items in the dashboard.