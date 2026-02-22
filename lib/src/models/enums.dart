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

enum CollisionDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}
