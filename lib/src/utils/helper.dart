import 'package:simple_dashboard/src/models/enums.dart';
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

  static bool assertRectsOrdered(List<ItemRect> rects, DashboardAxis axis) {
    assert(() {
      for (int i = 0; i < rects.length - 1; i++) {
        final current = rects[i].origin;
        final next = rects[i + 1].origin;

        if (!current.isBefore(next, axis)) {
          return false;
        }
      }

      return true;
    }(), "All item rects must be ordered by their top and left coordinates.");

    return true;
  }

  static bool assertRectsNotOverlapped(List<ItemRect> rects) {
    assert(() {
      for (int i = 0; i < rects.length; i++) {
        for (int j = i + 1; j < rects.length; j++) {
          if (rects[i].isOverlapped(rects[j])) {
            return false;
          }
        }
      }

      return true;
    }(), "All item rects must not be overlapped.");

    return true;
  }

  static String visualize(List<ItemRect> rects) {
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

    final grid = List.generate(maxY, (_) => List.filled(maxX, '.'));

    for (var i = 0; i < rects.length; i++) {
      final rect = rects[i];
      final char = String.fromCharCode(65 + (i % 26)); // A, B, C...
      for (int y = rect.top; y < rect.bottom; y++) {
        for (int x = rect.left; x < rect.right; x++) {
          if (grid[y][x] != '.') {
            grid[y][x] = '*'; // Mark overlaps with '*'
          } else {
            grid[y][x] = char;
          }
        }
      }
    }

    return grid.map((row) => row.join(' ')).join('\n');
  }
}
