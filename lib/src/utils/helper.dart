import 'package:collection/collection.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/models/enums.dart';

class DashboardAssertion {
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
}
