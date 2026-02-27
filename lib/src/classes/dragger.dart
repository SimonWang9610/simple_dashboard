import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

/// Defines which drag-and-drop strategy is used when rearranging items.
enum DragStrategy {
  /// Only allow a drop when the target area is completely empty.
  emptySpace,

  /// Allow a drop by swapping with the most-overlapped item, if that item can
  /// be relocated to a valid position.
  swap,
}

/// Interface implemented by [DashboardController] to support drag-and-drop
/// item rearrangement.
abstract interface class DashboardDragger {
  /// Begin a drag gesture for [item].
  ///
  /// [widgetSize] is the current pixel size of the widget and is used to
  /// derive the slot-to-pixel ratio for converting drag deltas into grid-slot
  /// deltas.
  void startDrag(LayoutItem item, Size widgetSize);

  /// Update the drag position by [delta] pixels.
  void updateDrag(Offset delta);

  /// Finish the drag.  When [confirmed] is true and a valid candidate position
  /// exists (placeholder is visible), the item is moved there.
  void endDrag(bool confirmed);

  // /// The active drag strategy; defaults to [DragStrategy.emptySpace].
  // DragStrategy get dragStrategy;
  // set dragStrategy(DragStrategy value);
}
