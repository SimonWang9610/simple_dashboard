import 'package:collection/collection.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';
import 'package:simple_dashboard/src/utils/helper.dart';

class DashboardLayoutEngine {
  /// Adopts a new rect for an item with the given flexes,
  /// try to fill the gap between existing rects first, otherwise place it at the end of the layout.
  ///
  /// [rects] must be ordered by their top and left coordinates.
  /// [flex] is the flex of the item to be adopted.
  /// [axis] is the main axis of the layout, which determines how the items are arranged and how the gaps are filled when adopting new rects.
  /// [maxMainAxisFlex] is the total flex of the main axis, which is used to determine the available space for the new rect.
  ///
  /// [crossStart] defines the search area;
  ///   for example, if the main axis is horizontal, it will only search for gaps in rows that are below the [crossStart] row.
  /// This is used to optimize the search process when reflowing items.
  static (int, ItemRect) adoptRect(
    List<ItemRect> rects,
    ItemFlex flex,
    DashboardAxis axis,
    int maxMainAxisFlex, {
    int crossStart = 0,
    int mainStart = 0,
  }) {
    assert(
      (axis == DashboardAxis.horizontal &&
              flex.horizontal <= maxMainAxisFlex) ||
          (axis == DashboardAxis.vertical && flex.vertical <= maxMainAxisFlex),
      'Flex exceeds max main axis bounds.',
    );

    assert(
      DashboardAssertion.assertRectsOrdered(rects, axis),
      "All item rects must be ordered by their top and left coordinates.",
    );

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

    final maxCrossSlot = axis == DashboardAxis.horizontal ? maxY : maxX;
    final availableMainSlot = axis == DashboardAxis.horizontal
        ? maxMainAxisFlex - flex.horizontal
        : maxMainAxisFlex - flex.vertical;

    int main = mainStart;

    for (int cross = crossStart; cross <= maxCrossSlot; cross++) {
      while (main <= availableMainSlot) {
        final candidate = ItemRect(
          axis == DashboardAxis.horizontal
              ? ItemCoordinate(main, cross)
              : ItemCoordinate(cross, main),
          flex,
        );

        /// we must check all rects in the layout to find any possible overlap with the candidate rect,
        /// as some rect may have large flexes along the cross axis and thus overlap with the candidate rect
        /// even if their origins are far apart on the main axis.
        final overlapped = rects.firstWhereOrNull(
          (rect) => rect.isOverlapped(candidate),
        );

        if (overlapped == null) {
          /// there is no overlap with existing rects,
          /// we can place the candidate rect at the current position.
          /// so we just find the correct index to insert the candidate rect
          /// while keeping the rects ordered by their top and left coordinates.
          final index = rects.indexWhere(
            (rect) => candidate.origin.isBefore(rect.origin, axis),
          );
          return (index == -1 ? rects.length : index, candidate);
        }

        main = axis == DashboardAxis.horizontal
            ? overlapped.right
            : overlapped.bottom;
      }

      /// purposely set to zero,
      /// mainStart is only used for the first cross loop,
      /// after that we want to start searching from the beginning of the main axis
      main = 0;
    }

    return (
      rects.length,
      ItemRect(
        axis == DashboardAxis.horizontal
            ? ItemCoordinate(0, maxCrossSlot + 1)
            : ItemCoordinate(maxCrossSlot + 1, 0),
        flex,
      ),
    );
  }

  static void sort(List<ItemRect> rects, DashboardAxis axis) {
    rects.sort((a, b) {
      return a.origin.isBefore(b.origin, axis) ? -1 : 1;
    });
  }

  static List<ItemRect> insertAt(
    List<ItemRect> rects,
    int index,
    ItemFlex flex,
    DashboardAxis axis,
    int mainAxisMaxFlex,
  ) {
    assert(
      DashboardAssertion.assertRectsOrdered(rects, axis),
      "All item rects must be ordered by their top and left coordinates.",
    );

    assert(
      DashboardAssertion.assertRectsNotOverlapped(rects),
      "All item rects must not be overlapped.",
    );

    final results = [...rects.getRange(0, index)];
    final afterRects = [...rects.getRange(index, rects.length)];

    ItemRect last = appendAtEnd(results, flex, axis, mainAxisMaxFlex);

    /// track all shifted rects to check for overlaps
    final shiftedRects = <ItemRect>[last];

    for (int i = 0; i < afterRects.length; i++) {
      final rect = afterRects[i];

      /// if any shifted rect overlaps with the current rect,
      /// we need to shift the current rect as well to avoid overlap,
      /// otherwise we can keep the current rect unchanged.
      final isAffected = shiftedRects.any(
        (shifted) => shifted.isOverlapped(rect),
      );

      if (!isAffected) {
        results.add(rect);
        continue;
      }

      final appended = appendAtEnd(results, rect.flexes, axis, mainAxisMaxFlex);
      shiftedRects.add(appended);
    }

    assert(
      DashboardAssertion.assertRectsOrdered(results, axis),
      "All item rects must be ordered by their top and left coordinates.",
    );

    return results;
  }

  static ItemRect appendAtEnd(
    List<ItemRect> rects,
    ItemFlex flex,
    DashboardAxis axis,
    int mainAxisMaxFlex,
  ) {
    final last = rects.lastOrNull;

    final (target, adopted) = adoptRect(
      rects,
      flex,
      axis,
      mainAxisMaxFlex,
      crossStart: axis == DashboardAxis.horizontal
          ? last?.top ?? 0
          : last?.left ?? 0,
      mainStart: axis == DashboardAxis.horizontal
          ? last?.right ?? 0
          : last?.bottom ?? 0,
    );

    assert(
      target == rects.length,
      "The adopted rect should be placed at the end of the layout.",
    );

    rects.add(adopted);

    assert(
      DashboardAssertion.assertRectsOrdered(rects, axis),
      "All item rects must be ordered by their top and left coordinates.",
    );

    assert(
      DashboardAssertion.assertRectsNotOverlapped(rects),
      "All item rects must not be overlapped.",
    );

    return adopted;
  }
}
