import 'package:flutter/rendering.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/sliver/models.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

abstract class SliverDashboardDelegate {
  final DashboardAxis axis;
  final int mainAxisSlots;
  final List<LayoutItem> items;

  SliverDashboardDelegate({
    required this.axis,
    required this.mainAxisSlots,
    required this.items,
  }) : assert(
         LayoutChecker.assertValidLayout(items, axis, mainAxisSlots),
         "Invalid layout: ${items.toString()}, axis: $axis, mainAxisSlots: $mainAxisSlots",
       );

  SliverDashboardLayout getLayout(SliverConstraints constraints);

  bool shouldRelayout(covariant SliverDashboardDelegate oldDelegate);
}

final class SliverDashboardDelegateWithFixedSlotCount
    extends SliverDashboardDelegate {
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

    int maxCrossAxisSlots = 0;

    for (final item in items) {
      final itemCrossAxisSlots = switch (axis) {
        DashboardAxis.horizontal => item.rect.bottom,
        DashboardAxis.vertical => item.rect.right,
      };

      if (itemCrossAxisSlots > maxCrossAxisSlots) {
        maxCrossAxisSlots = itemCrossAxisSlots;
      }
    }

    return SliverDashboardLayout(
      dashboardAxis: axis,
      maxCrossDashboardAxisSlots: maxCrossAxisSlots,
      mainDashboardAxisSlotExtent: mainDashboardAxisSlotExtent,
      crossDashboardAxisSlotExtent: mainDashboardAxisSlotExtent / aspectRatio,
      mainDashboardAxisSpacing: mainAxisSpacing,
      crossDashboardAxisSpacing: crossAxisSpacing,
      items: items,
    );
  }

  @override
  bool shouldRelayout(covariant SliverDashboardDelegate oldDelegate) {
    if (oldDelegate is! SliverDashboardDelegateWithFixedSlotCount) {
      return true;
    }

    return aspectRatio != oldDelegate.aspectRatio ||
        mainAxisSpacing != oldDelegate.mainAxisSpacing ||
        crossAxisSpacing != oldDelegate.crossAxisSpacing ||
        mainAxisSlots != oldDelegate.mainAxisSlots ||
        items != oldDelegate.items ||
        axis != oldDelegate.axis;
  }
}
