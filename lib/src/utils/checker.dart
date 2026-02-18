import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/models/layout_collision.dart';

abstract class LayoutChecker {
  static List<LayoutItem> findOverflowItems(
    Iterable<LayoutItem> items,
    DashboardAxis axis,
    int mainAxisSlots,
  ) {
    return items
        .where((item) => item.rect.isOverflow(axis, mainAxisSlots))
        .toList();
  }

  static (LayoutItem, LayoutItem)? findFirstConflictItems(
    Iterable<LayoutItem> items,
  ) {
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
          return (item, other);
        }
      }
    }

    return null;
  }

  static void assertNoConflicts(
    Iterable<LayoutItem> items,
  ) {
    assert(
      findFirstConflictItems(items) == null,
      "Layout contains conflicting items.",
    );
  }

  static bool assertNoDuplicatedIds(
    Iterable<LayoutItem> items,
  ) {
    bool hasDuplicates = false;

    assert(() {
      final ids = items.map((item) => item.id).toSet();

      hasDuplicates = ids.length != items.length;
      return true;
    }());

    return !hasDuplicates;
  }

  static void assertNoOverflow(
    Iterable<LayoutItem> items,
    DashboardAxis axis,
    int mainAxisSlots,
  ) {
    assert(
      findOverflowItems(items, axis, mainAxisSlots).isEmpty,
      "Layout contains overflow items.",
    );
  }

  static bool assertValidLayout(
    Iterable<LayoutItem> items,
    DashboardAxis axis,
    int mainAxisSlots,
  ) {
    bool hasOverflow = false;
    bool hasConflicts = false;
    bool hasDuplicatedIds = false;

    assert(() {
      hasOverflow = findOverflowItems(items, axis, mainAxisSlots).isNotEmpty;
      hasConflicts = findFirstConflictItems(items) != null;
      hasDuplicatedIds = !assertNoDuplicatedIds(items);

      return true;
    }());

    return !(hasOverflow || hasConflicts || hasDuplicatedIds);
  }

  static LayoutCollisionResult checkCollisions(
    Iterable<LayoutItem> items,
    LayoutRect rect,
  ) {
    final conflicts = items.where(
      (item) => item.rect.hasConflicts(rect) && item.rect != rect,
    );

    final Map<CollisionDirection, List<LayoutItem>> result = {};

    for (final item in conflicts) {
      final itemRect = item.rect;

      final isTop = rect.top < itemRect.top;
      final isLeft = rect.left < itemRect.left;

      final direction = switch (isTop) {
        true => switch (isLeft) {
          true => CollisionDirection.topLeft,
          false => CollisionDirection.topRight,
        },
        false => switch (isLeft) {
          true => CollisionDirection.bottomLeft,
          false => CollisionDirection.bottomRight,
        },
      };

      result.putIfAbsent(direction, () => []).add(item);
    }

    return LayoutCollisionResult(
      rect: rect,
      topLeft: result[CollisionDirection.topLeft] ?? [],
      topRight: result[CollisionDirection.topRight] ?? [],
      bottomLeft: result[CollisionDirection.bottomLeft] ?? [],
      bottomRight: result[CollisionDirection.bottomRight] ?? [],
    );
  }

  static void debugLayoutAssertions(
    Iterable<LayoutItem> items,
    DashboardAxis axis,
    int mainAxisSlots,
  ) {
    assert(
      LayoutChecker.assertNoDuplicatedIds(items),
      "Each item in the dashboard must have a unique id. Duplicated ids found in items: ${items.map((e) => e.id)}",
    );

    assert(
      () {
        final overflowed = LayoutChecker.findOverflowItems(
          items,
          axis,
          mainAxisSlots,
        );

        for (final item in overflowed) {
          debugPrint(
            "[${item.id}] overflowed: mainSlots: ${axis == DashboardAxis.horizontal ? item.rect.right : item.rect.bottom}, mainAxisSlots=$mainAxisSlots",
          );
        }

        return overflowed.isEmpty;
      }(),
      "Some items are out of the dashboard bounds. Please ensure all items fit within the dashboard's main axis slots.",
    );

    assert(
      () {
        final conflicts = LayoutChecker.findFirstConflictItems(items);
        if (conflicts != null) {
          final (item1, item2) = conflicts;
          debugPrint(
            "[${item1.id}] and [${item2.id}] are in conflict: rect1=${item1.rect}, rect2=${item2.rect}",
          );
        }
        return conflicts == null;
      }(),
      "Some items are overlapped each other. Please ensure no items overlap with each other.",
    );
  }
}
