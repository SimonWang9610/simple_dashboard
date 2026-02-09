import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';

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

        final overlapped = rects.firstWhereOrNull(
          (rect) => rect.isOverlapped(candidate),
        );

        if (overlapped == null) {
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
        axis == Axis.horizontal
            ? ItemCoordinate(0, maxCrossSlot + 1)
            : ItemCoordinate(maxCrossSlot + 1, 0),
        flex,
      ),
    );
  }

  static List<ItemRect> reflow(
    List<ItemRect> rects,
    ItemRect reference,
    DashboardAxis axis,
    int maxMainAxisFlex,
  ) {
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

    final newRects = <ItemRect>[];

    ItemRect? previous;

    for (final rect in rects) {
      if (rect.origin.isBefore(reference.origin, axis)) {
        newRects.add(rect);
      } else {
        final (index, adopted) = adoptRect(
          newRects,
          rect.flexes,
          axis,
          maxMainAxisFlex,

          /// avoid the adopted rect being placed before the reference rect,
          /// which can cause unnecessary movement of the reference rect and other rects after it.
          crossStart: axis == DashboardAxis.horizontal
              ? previous?.top ?? 0
              : previous?.left ?? 0,
          mainStart: axis == DashboardAxis.horizontal
              ? previous?.right ?? 0
              : previous?.bottom ?? 0,
        );

        newRects.insert(index, adopted);
        previous = adopted;
      }
    }

    assert(() {
      for (int i = 0; i < newRects.length - 1; i++) {
        final current = newRects[i].origin;
        final next = newRects[i + 1].origin;

        if (!current.isBefore(next, axis)) {
          return false;
        }
      }

      return true;
    }(), "newRects must be ordered by their top and left coordinates.");

    return newRects;
  }

  static void sort(List<ItemRect> rects, DashboardAxis axis) {
    rects.sort((a, b) {
      return a.origin.isBefore(b.origin, axis) ? -1 : 1;
    });
  }
}
