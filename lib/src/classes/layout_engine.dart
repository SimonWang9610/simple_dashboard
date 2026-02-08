import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';

class DashboardLayoutEngine {
  static ItemRect insertRect(
    List<ItemRect> rects,
    ItemFlex flex,
    Axis axis,
    int maxMainAxisFlex,
  ) {
    assert(
      (axis == Axis.horizontal && flex.horizontal <= maxMainAxisFlex) ||
          (axis == Axis.vertical && flex.vertical <= maxMainAxisFlex),
      'Flex exceeds max main axis bounds.',
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

    final maxCrossFlex = axis == Axis.horizontal ? maxY : maxX;
    final availableMainFlex = axis == Axis.horizontal
        ? maxMainAxisFlex - flex.horizontal
        : maxMainAxisFlex - flex.vertical;

    int main = 0;

    for (int cross = 0; cross <= maxCrossFlex; cross++) {
      main = 0;

      while (main <= availableMainFlex) {
        final candidate = ItemRect(
          axis == Axis.horizontal
              ? ItemCoordinate(main, cross)
              : ItemCoordinate(cross, main),
          flex,
        );

        final overlapped = rects.firstWhereOrNull(
          (rect) => rect.isOverlapped(candidate),
        );

        if (overlapped == null) {
          return candidate;
        }

        main = axis == Axis.horizontal ? overlapped.right : overlapped.bottom;
      }
    }

    return ItemRect(
      axis == Axis.horizontal
          ? ItemCoordinate(0, maxCrossFlex)
          : ItemCoordinate(maxCrossFlex, 0),
      flex,
    );
  }
}
