import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

enum ResizeDirection {
  left,
  right,
  up,
  down,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

abstract interface class DashboardResizer {
  void startResize(ResizeDirection direction, LayoutItem item);
  void updateResize(Offset localPosition);
  void endResize(bool confirmed);
}
