import 'package:flutter/rendering.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/models/enums.dart';

class SliverDashboardLayout {
  final DashboardAxis dashboardAxis;
  final int maxCrossDashboardAxisSlots;
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
    required this.maxCrossDashboardAxisSlots,
    this.mainDashboardAxisSpacing = 0,
    this.crossDashboardAxisSpacing = 0,
  });

  double get mainDashboardAxisStride =>
      mainDashboardAxisSlotExtent + mainDashboardAxisSpacing;

  double get crossDashboardAxisStride =>
      crossDashboardAxisSlotExtent + crossDashboardAxisSpacing;

  int getMinChildIndexForScrollOffset(double scrollOffset) {
    if (crossDashboardAxisStride <= 0) return 0;

    final minCrossAxisSlots =
        ((scrollOffset + crossDashboardAxisSpacing) / crossDashboardAxisStride)
            .floor();

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      final itemCrossAxisStart = dashboardAxis == DashboardAxis.horizontal
          ? item.rect.top
          : item.rect.left;

      if (itemCrossAxisStart >= minCrossAxisSlots) {
        return i;
      }
    }

    return items.length - 1;
  }

  int? getMaxChildIndexForScrollOffset(double scrollOffset) {
    if (crossDashboardAxisStride <= 0) return 0;

    final maxCrossAxisSlots =
        ((scrollOffset - crossDashboardAxisSpacing) / crossDashboardAxisStride)
            .ceil();

    for (int i = items.length - 1; i >= 0; i--) {
      final item = items[i];

      final itemCrossAxisEnd = dashboardAxis == DashboardAxis.horizontal
          ? item.rect.bottom
          : item.rect.right;

      if (itemCrossAxisEnd <= maxCrossAxisSlots) {
        return i;
      }
    }

    return items.length - 1;
  }

  double computeMaxScrollOffset() {
    return maxCrossDashboardAxisSlots * crossDashboardAxisStride -
        crossDashboardAxisSpacing;
  }

  SliverDashboardGeometry computeItemGeometry(int index) {
    final itemRect = items[index].rect;

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
}
