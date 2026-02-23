import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

abstract class SliverDashboardLayoutDelegate {
  final DashboardAxis axis;
  final int mainAxisSlots;
  final List<LayoutItem> items;

  SliverDashboardLayoutDelegate({
    required this.axis,
    required this.mainAxisSlots,
    required this.items,
  }) : assert(
         LayoutChecker.debugAssertValidLayout(items, axis, mainAxisSlots),
         "Invalid layout: ${items.toString()}, axis: $axis, mainAxisSlots: $mainAxisSlots",
       ),
       assert(
         DashboardHelper.assertSorted(items, axis),
         "Items must be sorted by their position along the main axis; "
         "otherwise, the layout delegate may produce incorrect layouts and cause rendering issues.",
       );

  SliverDashboardLayout getLayout(SliverConstraints constraints);

  bool shouldRelayout(covariant SliverDashboardLayoutDelegate oldDelegate) {
    return oldDelegate.axis != axis ||
        oldDelegate.mainAxisSlots != mainAxisSlots ||
        !listEquals(oldDelegate.items, items);
  }
}

final class SliverDashboardDelegateWithFixedSlotCount
    extends SliverDashboardLayoutDelegate {
  /// The aspect ratio of each slot in the main axis.
  /// mainAxisSlotExtent / crossAxisSlotExtent = aspectRatio.
  final double aspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  SliverDashboardDelegateWithFixedSlotCount({
    required super.mainAxisSlots,
    required super.items,
    required super.axis,
    this.aspectRatio = 1.0,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
  });

  @override
  SliverDashboardLayout getLayout(SliverConstraints constraints) {
    assert(
      () {
        return switch (axis) {
          DashboardAxis.vertical => constraints.axis == Axis.horizontal,
          DashboardAxis.horizontal => constraints.axis == Axis.vertical,
        };
      }(),
      "SliverDashboardDelegateWithFixedSlotCount's axis must be perpendicular to the sliver's axis.",
    );

    final usableMainAxisSlotExtent =
        constraints.crossAxisExtent - (mainAxisSlots - 1) * mainAxisSpacing;

    final mainDashboardAxisSlotExtent =
        usableMainAxisSlotExtent / mainAxisSlots;

    return SliverDashboardLayout(
      dashboardAxis: axis,
      mainDashboardAxisSlotExtent: mainDashboardAxisSlotExtent,
      crossDashboardAxisSlotExtent: mainDashboardAxisSlotExtent / aspectRatio,
      mainDashboardAxisSpacing: mainAxisSpacing,
      crossDashboardAxisSpacing: crossAxisSpacing,
      items: items,
    );
  }

  @override
  bool shouldRelayout(covariant SliverDashboardLayoutDelegate oldDelegate) {
    if (oldDelegate is! SliverDashboardDelegateWithFixedSlotCount) {
      return true;
    }

    return aspectRatio != oldDelegate.aspectRatio ||
        mainAxisSpacing != oldDelegate.mainAxisSpacing ||
        crossAxisSpacing != oldDelegate.crossAxisSpacing ||
        super.shouldRelayout(oldDelegate);
  }
}

class SliverDashboardLayout {
  final DashboardAxis dashboardAxis;
  final double mainDashboardAxisSlotExtent;
  final double crossDashboardAxisSlotExtent;

  final double mainDashboardAxisSpacing;
  final double crossDashboardAxisSpacing;
  final List<LayoutItem> items;

  const SliverDashboardLayout({
    required this.mainDashboardAxisSlotExtent,
    required this.crossDashboardAxisSlotExtent,
    required this.items,
    required this.dashboardAxis,
    this.mainDashboardAxisSpacing = 0,
    this.crossDashboardAxisSpacing = 0,
  });

  /// The distance from the leading edge of one slot to
  ///  the leading edge of the next slot in the main axis.
  double get mainDashboardAxisStride =>
      mainDashboardAxisSlotExtent + mainDashboardAxisSpacing;

  /// The distance from the leading edge of one slot to
  ///  the leading edge of the next slot in the cross axis.
  double get crossDashboardAxisStride =>
      crossDashboardAxisSlotExtent + crossDashboardAxisSpacing;

  /// Returns the index of the first item that should be visible at the given scroll offset.
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    if (crossDashboardAxisStride <= 0 || items.isEmpty) return 0;

    final minCrossAxisSlots = (scrollOffset / crossDashboardAxisStride).ceil();

    int index = 0;

    while (index < items.length) {
      final item = items[index];

      final itemCrossAxisEnd = dashboardAxis == DashboardAxis.horizontal
          ? item.rect.bottom
          : item.rect.right;

      if (itemCrossAxisEnd > minCrossAxisSlots) {
        return index;
      }

      index++;
    }

    return index < items.length ? index : items.length - 1;
  }

  /// Returns the index of the last item that should be visible at the given scroll offset.
  int? getMaxChildIndexForScrollOffset(double scrollOffset) {
    if (crossDashboardAxisStride <= 0 || items.isEmpty) return 0;

    final maxCrossAxisSlots =
        ((scrollOffset - crossDashboardAxisSpacing) / crossDashboardAxisStride)
            .floor();

    int index = items.length - 1;

    while (index >= 0) {
      final item = items[index];

      final itemCrossAxisStart = dashboardAxis == DashboardAxis.horizontal
          ? item.rect.top
          : item.rect.left;

      if (itemCrossAxisStart < maxCrossAxisSlots) {
        return index;
      }

      index--;
    }

    return 0;
  }

  int get maxCrossDashboardAxisSlots {
    int maxCrossAxisSlots = 0;

    for (final item in items) {
      final itemCrossAxisSlots = switch (dashboardAxis) {
        DashboardAxis.horizontal => item.rect.bottom,
        DashboardAxis.vertical => item.rect.right,
      };

      if (itemCrossAxisSlots > maxCrossAxisSlots) {
        maxCrossAxisSlots = itemCrossAxisSlots;
      }
    }

    return maxCrossAxisSlots;
  }

  double computeMaxScrollOffset() {
    /// There is no item in the dashboard
    /// return the zero scroll offset
    if (items.isEmpty) {
      return 0;
    }

    return maxCrossDashboardAxisSlots * crossDashboardAxisStride -
        crossDashboardAxisSpacing;
  }

  SliverDashboardGeometry computeGeometry(int index) {
    assert(
      items.isEmpty || (index >= 0 && index < items.length),
      "Index out of range: $index, items length: ${items.length}",
    );

    /// If there is no item, return a default geometry with zero extents.
    if (items.isEmpty) {
      return const SliverDashboardGeometry(
        scrollOffset: 0,
        crossAxisOffset: 0,
        mainAxisExtent: 0,
        crossAxisExtent: 0,
      );
    }

    final item = items[index];
    return computeItemGeometry(item.rect);
  }

  SliverDashboardGeometry computeItemGeometry(LayoutRect itemRect) {
    final (dx, dy) = switch (dashboardAxis) {
      DashboardAxis.horizontal => (
        itemRect.left * mainDashboardAxisStride,
        itemRect.top * crossDashboardAxisStride,
      ),
      DashboardAxis.vertical => (
        itemRect.left * crossDashboardAxisStride,
        itemRect.top * mainDashboardAxisStride,
      ),
    };

    final rectSize = itemRect.size;

    final (widthExtent, heightExtent) = switch (dashboardAxis) {
      DashboardAxis.horizontal => (
        rectSize.width * mainDashboardAxisStride - mainDashboardAxisSpacing,
        rectSize.height * crossDashboardAxisStride - crossDashboardAxisSpacing,
      ),
      DashboardAxis.vertical => (
        rectSize.width * crossDashboardAxisStride - crossDashboardAxisSpacing,
        rectSize.height * mainDashboardAxisStride - mainDashboardAxisSpacing,
      ),
    };

    final (
      scrollOffset,
      crossAxisOffset,
      mainAxisExtent,
      crossAxisExtent,
    ) = switch (dashboardAxis) {
      DashboardAxis.horizontal => (dy, dx, heightExtent, widthExtent),
      DashboardAxis.vertical => (dx, dy, widthExtent, heightExtent),
    };

    return SliverDashboardGeometry(
      scrollOffset: scrollOffset,
      crossAxisOffset: crossAxisOffset,
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
    );
  }
}

class SliverDashboardGeometry {
  final double scrollOffset;
  final double crossAxisOffset;
  final double mainAxisExtent;
  final double crossAxisExtent;

  const SliverDashboardGeometry({
    required this.scrollOffset,
    required this.crossAxisOffset,
    required this.mainAxisExtent,
    required this.crossAxisExtent,
  });

  double get trailingScrollOffset => scrollOffset + mainAxisExtent;

  BoxConstraints getBoxConstraints(SliverConstraints constraints) {
    final result = constraints.asBoxConstraints(
      minExtent: mainAxisExtent,
      maxExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
    );
    return result;
  }

  Size getSize(DashboardAxis axis) {
    return switch (axis) {
      DashboardAxis.horizontal => Size(crossAxisExtent, mainAxisExtent),
      DashboardAxis.vertical => Size(mainAxisExtent, crossAxisExtent),
    };
  }

  Offset getOrigin(DashboardAxis axis) {
    return switch (axis) {
      DashboardAxis.horizontal => Offset(crossAxisOffset, scrollOffset),
      DashboardAxis.vertical => Offset(scrollOffset, crossAxisOffset),
    };
  }

  BoxItemGeometry getBoxItemGeometry(DashboardAxis axis) {
    return BoxItemGeometry(
      origin: getOrigin(axis),
      size: getSize(axis),
    );
  }
}

class BoxItemGeometry {
  final Offset origin;
  final Size size;

  const BoxItemGeometry({
    required this.origin,
    required this.size,
  });
}
