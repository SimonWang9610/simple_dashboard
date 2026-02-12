import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

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
  /// If [LayoutRect.isOverflow] is true, it will be constrained via [LayoutSize.constrain]
  /// and then repositioned using [DashboardAppendPositioner]
  ///
  /// The result may BREAK the original [LayoutRect] of the items,
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
    final guarded = _guard(items, axis, mainAxisSlots);

    if (guarded != null) {
      return guarded;
    }

    /// respect to the original position ordering of the items
    final sortedItems = DashboardHelper.sort(items, axis);

    int maxCrossSlots = 0;

    List<LayoutItem> guardedItems = [];

    for (final item in sortedItems) {
      final hasOverflow = item.rect.isOverflow(axis, mainAxisSlots);

      final hasCollision = LayoutChecker.checkCollisions(
        guardedItems,
        item.rect,
      ).hasCollision;

      if (!hasOverflow && !hasCollision) {
        guardedItems.add(item);
      } else {
        guardedItems =
            DashboardAppendPositioner(
              items: guardedItems,
              axis: axis,
              mainAxisSlots: mainAxisSlots,
              maxCrossSlots: maxCrossSlots,
            ).position(
              item.id,
              item.rect.size.constrain(axis, mainAxisSlots),
            );
      }

      final crossSlots = axis == DashboardAxis.horizontal
          ? guardedItems.last.rect.bottom
          : guardedItems.last.rect.right;

      maxCrossSlots = crossSlots > maxCrossSlots ? crossSlots : maxCrossSlots;
    }

    return guardedItems;
  }

  static List<LayoutItem>? _guard(
    Iterable<LayoutItem> items,
    DashboardAxis axis,
    int mainAxisSlots,
  ) {
    final overflowed = LayoutChecker.findOverflowItems(
      items,
      axis,
      mainAxisSlots,
    );

    final conflicts = LayoutChecker.findFirstConflictItems(items);

    assert(() {
      for (final item in overflowed) {
        debugPrint(
          "[${item.id}] overflowed: mainSlots: ${axis == DashboardAxis.horizontal ? item.rect.right : item.rect.bottom}, mainAxisSlots=$mainAxisSlots",
        );
      }

      if (conflicts != null) {
        final (item1, item2) = conflicts;
        debugPrint(
          "[${item1.id}] and [${item2.id}] are in conflict: rect1=${item1.rect}, rect2=${item2.rect}",
        );
      }

      return true;
    }());

    if (overflowed.isEmpty && conflicts == null) {
      return items.toList();
    }

    return null;
  }
}
