import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/models/enums.dart';

class LayoutExtentUnit {
  final double horizontal;
  final double vertical;

  final double horizontalSpacing;
  final double verticalSpacing;

  const LayoutExtentUnit({
    required this.horizontal,
    required this.vertical,
    this.horizontalSpacing = 0,
    this.verticalSpacing = 0,
  });

  @override
  String toString() {
    return 'LayoutExtentUnit(horizontal: $horizontal, vertical: $vertical, horizontalSpacing: $horizontalSpacing, verticalSpacing: $verticalSpacing)';
  }
}

abstract class DashboardLayoutDelegate {
  const DashboardLayoutDelegate();

  LayoutExtentUnit computeLayoutExtentUnit(
    BoxConstraints constraints,
    DashboardAxis axis,
    int mainAxisSlots,
  );

  Rect computeItemRect(LayoutRect layoutRect, LayoutExtentUnit extents) {
    final dx = layoutRect.x * (extents.horizontal + extents.horizontalSpacing);
    final dy = layoutRect.y * (extents.vertical + extents.verticalSpacing);
    final width =
        layoutRect.size.width * extents.horizontal +
        (layoutRect.size.width - 1) * extents.horizontalSpacing;
    final height =
        layoutRect.size.height * extents.vertical +
        (layoutRect.size.height - 1) * extents.verticalSpacing;

    return Rect.fromLTWH(dx, dy, width, height);
  }

  bool shouldRelayout(covariant DashboardLayoutDelegate oldDelegate);
}

final class DashboardAspectRatioDelegate extends DashboardLayoutDelegate {
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double aspectRatio;

  const DashboardAspectRatioDelegate({
    this.aspectRatio = 1.0,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
  }) : assert(aspectRatio > 0),
       assert(mainAxisSpacing >= 0),
       assert(crossAxisSpacing >= 0);

  @override
  LayoutExtentUnit computeLayoutExtentUnit(
    BoxConstraints constraints,
    DashboardAxis axis,
    int mainAxisSlots,
  ) {
    assert(
      () {
        if (axis == DashboardAxis.horizontal) {
          return constraints.hasBoundedWidth;
        } else {
          return constraints.hasBoundedHeight;
        }
      }(),
      "DashboardAspectRatioDelegate requires bounded constraints to compute layout extent unit.",
    );

    final mainAxisExtent = axis == DashboardAxis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;

    final mainAxisSlotExtent =
        (mainAxisExtent - (mainAxisSlots - 1) * mainAxisSpacing) /
        mainAxisSlots;

    final (h, v, hSpacing, vSpacing) = switch (axis) {
      DashboardAxis.horizontal => (
        mainAxisSlotExtent,
        mainAxisSlotExtent / aspectRatio,
        mainAxisSpacing,
        crossAxisSpacing,
      ),
      DashboardAxis.vertical => (
        mainAxisSlotExtent * aspectRatio,
        mainAxisSlotExtent,
        crossAxisSpacing,
        mainAxisSpacing,
      ),
    };

    return LayoutExtentUnit(
      horizontal: h,
      vertical: v,
      horizontalSpacing: hSpacing,
      verticalSpacing: vSpacing,
    );
  }

  @override
  bool shouldRelayout(covariant DashboardAspectRatioDelegate oldDelegate) {
    return aspectRatio != oldDelegate.aspectRatio ||
        mainAxisSpacing != oldDelegate.mainAxisSpacing ||
        crossAxisSpacing != oldDelegate.crossAxisSpacing;
  }
}
