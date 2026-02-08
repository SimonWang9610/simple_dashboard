import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/models/item.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';

class DashboardAssertion {
  /// Asserts that the given [flex] is within the given [range].
  /// Throws an [AssertionError] if the assertion fails.
  static bool assertValidFlex(ItemFlexRange range, ItemFlex flex) {
    assert(
      range.min.horizontal <= flex.horizontal &&
          flex.horizontal <= range.max.horizontal &&
          range.min.vertical <= flex.vertical &&
          flex.vertical <= range.max.vertical,
      'The initial flexes of the item must be within the specified range.',
    );

    return true;
  }

  static bool assertIdNotDuplicate(List<DashboardItem> items) {
    assert(() {
      final ids = items.map((item) => item.id).toList();
      final uniqueIds = ids.toSet();

      return ids.length == uniqueIds.length;
    }(), "All item ids must be unique.");

    return true;
  }

  static bool assertRectsOrdered(List<ItemRect> rects, Axis axis) {
    assert(() {
      for (int i = 0; i < rects.length - 1; i++) {
        final current = rects[i];
        final next = rects[i + 1];

        if (axis == Axis.horizontal) {
          if (next.left > current.right) {
            return false;
          }
        } else {
          if (next.top > current.bottom) {
            return false;
          }
        }
      }

      return true;
    }(), "All item rects must be ordered by their top and left coordinates.");

    return true;
  }
}
