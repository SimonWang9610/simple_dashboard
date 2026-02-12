import 'package:collection/collection.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

class DashboardHelper {
  static String visualize(List<LayoutRect> rects) {
    int maxX = 0;
    int maxY = 0;

    for (final rect in rects) {
      if (rect.right > maxX) {
        maxX = rect.right;
      }

      if (rect.bottom > maxY) {
        maxY = rect.bottom;
      }
    }

    final grid = List.generate(maxY, (_) => List.filled(maxX, '-'));

    for (var i = 0; i < rects.length; i++) {
      final rect = rects[i];
      final char = String.fromCharCode(65 + (i % 26)); // A, B, C...
      for (int y = rect.top; y < rect.bottom; y++) {
        for (int x = rect.left; x < rect.right; x++) {
          if (grid[y][x] != '-') {
            grid[y][x] = '*'; // Mark overlaps with '*'
          } else {
            grid[y][x] = char;
          }
        }
      }
    }

    final visualization = grid.map((row) => row.join(' ')).join('\n');

    return visualization;
  }

  static void checkNoOverflow(
    Iterable<LayoutItem> items,
    DashboardAxis axis,
    int mainAxisSlots,
  ) {
    for (final item in items) {
      final hasOverflow = switch (axis) {
        DashboardAxis.horizontal => item.rect.size.width > mainAxisSlots,
        DashboardAxis.vertical => item.rect.size.height > mainAxisSlots,
      };

      if (hasOverflow) {
        throw ArgumentError(
          "Layout contains an item that exceeds the maximum slot count of the main axis: ${item.id}",
        );
      }
    }
  }

  static void checkNoConflict(Iterable<LayoutItem> items) {
    final sorted = items.toList()
      ..sort((a, b) => a.rect.left.compareTo(b.rect.left));

    final int n = sorted.length;

    for (int i = 0; i < n; i++) {
      final item = sorted[i];
      final rect = item.rect;

      // Inner loop only checks items that could potentially overlap on the X-axis
      for (int j = i + 1; j < n; j++) {
        final other = sorted[j];
        final otherRect = other.rect;

        // PRUNING STEP:
        // Since the list is sorted by 'left', if 'other.left' is already
        // beyond 'item.right', no subsequent items in the list can
        // possibly collide with 'item'. We can safely break the inner loop.
        if (otherRect.left >= rect.right) {
          break;
        }

        // If we are here, they overlap partially on the X-axis.
        // Now we check if they also overlap on the Y-axis.
        if (rect.hasConflicts(otherRect)) {
          throw ArgumentError(
            "Layout contains conflicting items: ${item.id} and ${other.id}",
          );
        }
      }
    }
  }

  static List<LayoutItem> sort(Iterable<LayoutItem> items, DashboardAxis axis) {
    return items.sorted(
      (a, b) => a.rect.compare(b.rect, axis),
    );
  }

  static bool assertSorted(
    Iterable<LayoutItem> items,
    DashboardAxis axis,
  ) {
    LayoutRect? previousRect;

    for (final item in items) {
      final rect = item.rect;

      if (previousRect != null) {
        final comparison = previousRect.compare(rect, axis);
        if (comparison > 0) {
          return false;
        }
      }

      previousRect = rect;
    }

    return true;
  }

  /// Adopts the given layout items to fit within the specified axis and main axis slot constraints.
  ///
  /// If an item's size exceeds the main axis slot count, it will be constrained via [LayoutSize.constrain]
  /// and then repositioned using [DashboardAppendPositioner]
  ///
  /// Items that already fit within the constraints will be kept as is.
  ///
  /// The result may break the original [LayoutRect] of the items,
  /// but will ensure that all items fit within the dashboard's layout rules.
  ///
  /// Typically, it happens when the dashboard's axis or main axis slot count is changed.
  ///
  /// If [DashboardAxis] changes, some items may not fit the new main axis slot count and need to be repositioned.
  ///
  /// If [mainAxisSlots] decreases, some items may also need to be repositioned to fit the new slot count;
  /// However, if [mainAxisSlots] increases, all items will still fit without repositioning.
  ///
  /// [oldMainAxisSlots] is used to determine whether the main axis slots have been reduced,
  /// which may cause more items to require repositioning.
  ///
  /// When the main axis slots are reduced, the main extent of each flex will increase,
  /// which may cause some items are overflowed along the main axis and thus require repositioning.
  ///
  /// When the main axis slots are increased, the main extent of each flex will decrease,
  /// so we can safely assume that no items will be overflowed along the main axis,
  /// and thus no items will require repositioning.
  static List<LayoutItem> adoptMetrics(
    Iterable<LayoutItem> items,
    DashboardAxis axis,
    int mainAxisSlots, {
    int? oldMainAxisSlots,
  }) {
    List<LayoutItem> adoptedItems = [];

    int maxCrossSlots = 0;

    final mainAxisSlotsCollapsed =
        oldMainAxisSlots != null && oldMainAxisSlots > mainAxisSlots;

    for (final item in items) {
      final constrainedSize = item.rect.size.constrain(axis, mainAxisSlots);

      /// If the item already fits within the main axis slots
      /// and we are not collapsing the main axis slots, we can keep it as is.
      if (constrainedSize == item.rect.size && !mainAxisSlotsCollapsed) {
        adoptedItems.add(item);
      } else {
        adoptedItems = DashboardAppendPositioner(
          items: adoptedItems,
          axis: axis,
          mainAxisSlots: mainAxisSlots,
          maxCrossSlots: maxCrossSlots,
        ).position(item.id, constrainedSize);
      }

      final crossSlots = axis == DashboardAxis.horizontal
          ? adoptedItems.last.rect.bottom
          : adoptedItems.last.rect.right;

      maxCrossSlots = crossSlots > maxCrossSlots ? crossSlots : maxCrossSlots;
    }

    return adoptedItems;
  }

  /// Similar to [adoptMetrics],
  /// but also ensures that the final layout is free of any overflow or conflicts.
  ///
  /// Typically it is used to guard against invalid layout states for initial items.
  static List<LayoutItem> guardMetrics(
    Iterable<LayoutItem> items,
    DashboardAxis axis,
    int mainAxisSlots,
  ) {
    bool shouldReposition = false;

    try {
      checkNoOverflow(items, axis, mainAxisSlots);
      checkNoConflict(items);
      shouldReposition = false;
    } catch (e) {
      shouldReposition = true;
    }

    if (!shouldReposition) {
      return items.toList();
    }

    /// respect to the original position ordering of the items
    final sortedItems = DashboardHelper.sort(items, axis);

    int maxCrossSlots = 0;

    List<LayoutItem> guardedItems = [];

    for (final item in sortedItems) {
      final constrainedSize = item.rect.size.constrain(axis, mainAxisSlots);

      guardedItems = DashboardAppendPositioner(
        items: guardedItems,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: maxCrossSlots,
      ).position(item.id, constrainedSize);

      final crossSlots = axis == DashboardAxis.horizontal
          ? guardedItems.last.rect.bottom
          : guardedItems.last.rect.right;

      maxCrossSlots = crossSlots > maxCrossSlots ? crossSlots : maxCrossSlots;
    }

    return guardedItems;
  }
}
