import 'package:flutter/widgets.dart';

/// A class that represents the axis of the dashboard.
/// This is used to determine the layout main axis of the items in the dashboard.
///
/// It is in the reverse direction of the scroll direction, which means that if the main axis is horizontal, the scroll direction is vertical, and vice versa.
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
