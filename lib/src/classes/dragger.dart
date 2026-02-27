import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

class DragInfo {
  final LayoutItem item;
  final Size size;
  final Offset origin;
  final Widget feedback;

  const DragInfo({
    required this.item,
    required this.size,
    required this.origin,
    required this.feedback,
  });
}

abstract interface class DashboardDragger {
  void startDrag(DragInfo dragInfo);
  void updateDrag(Offset delta);
  void endDrag(bool confirmed);

  bool get isDragging;
}
