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
  /// Begin a resize gesture.
  ///
  /// [widgetSize] is the current pixel size of the widget being resized and is
  /// used to derive the slot-to-pixel ratio needed for converting drag deltas
  /// into grid-slot deltas.
  void startResize(ResizeDirection direction, LayoutItem item, Size widgetSize);
  void updateResize(Offset localPosition, Offset delta);
  void endResize(bool confirmed);

  DashboardPlaceholderPainter? get placeholderPainter;
}
