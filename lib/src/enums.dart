import 'package:flutter/widgets.dart';

/// A class that represents the axis of the dashboard.
/// This is used to determine the layout main axis of the items in the dashboard.
///
/// It is orthogonal to the scroll axis of the sliver.
/// For example, if the dashboard axis is [DashboardAxis.horizontal],
/// the items in the dashboard will be laid out horizontally,
/// and the scroll axis of the sliver should be [Axis.vertical].
enum DashboardAxis {
  horizontal,
  vertical
  ;

  Axis get scrollDirection {
    return switch (this) {
      DashboardAxis.horizontal => Axis.vertical,
      DashboardAxis.vertical => Axis.horizontal,
    };
  }
}

extension DashboardAxisExtension on Axis {
  DashboardAxis get dashboard {
    return switch (this) {
      Axis.horizontal => DashboardAxis.vertical,
      Axis.vertical => DashboardAxis.horizontal,
    };
  }
}

enum ResizeDirection {
  left,
  right,
  up,
  down,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight
  ;

  bool get isLeftEdge =>
      this == ResizeDirection.left ||
      this == ResizeDirection.topLeft ||
      this == ResizeDirection.bottomLeft;

  bool get isRightEdge =>
      this == ResizeDirection.right ||
      this == ResizeDirection.topRight ||
      this == ResizeDirection.bottomRight;

  bool get isTopEdge =>
      this == ResizeDirection.up ||
      this == ResizeDirection.topLeft ||
      this == ResizeDirection.topRight;

  bool get isBottomEdge =>
      this == ResizeDirection.down ||
      this == ResizeDirection.bottomLeft ||
      this == ResizeDirection.bottomRight;

  bool get isHorizontal =>
      this == ResizeDirection.left ||
      this == ResizeDirection.right ||
      this == ResizeDirection.topLeft ||
      this == ResizeDirection.topRight ||
      this == ResizeDirection.bottomLeft ||
      this == ResizeDirection.bottomRight;

  bool get isVertical =>
      this == ResizeDirection.up ||
      this == ResizeDirection.down ||
      this == ResizeDirection.topLeft ||
      this == ResizeDirection.topRight ||
      this == ResizeDirection.bottomLeft ||
      this == ResizeDirection.bottomRight;

  ResizeDirection get opposite {
    return switch (this) {
      ResizeDirection.left => ResizeDirection.right,
      ResizeDirection.right => ResizeDirection.left,
      ResizeDirection.up => ResizeDirection.down,
      ResizeDirection.down => ResizeDirection.up,
      ResizeDirection.topLeft => ResizeDirection.bottomRight,
      ResizeDirection.topRight => ResizeDirection.bottomLeft,
      ResizeDirection.bottomLeft => ResizeDirection.topRight,
      ResizeDirection.bottomRight => ResizeDirection.topLeft,
    };
  }
}

enum MoveDropStrategy {
  noCollision,
  reflow,
}
