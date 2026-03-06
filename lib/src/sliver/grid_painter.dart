import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

class DashboardGridPainter {
  final ColorFilter color;
  final double strokeWidth;

  DashboardGridPainter({
    this.color = const ColorFilter.mode(
      Color(0x11000000),
      BlendMode.srcIn,
    ),
    this.strokeWidth = 1.0,
  });

  void paint(
    Canvas canvas,
    SliverDashboardLayout layout,
    SliverConstraints constraints,
    int mainDashboardAxisSlots,
    double paintExtent,
    Offset originOffset,
    Offset mainAxisUnit,
    Offset crossAxisUnit,
  ) {
    final scrollOffset = constraints.scrollOffset;
    final crossAxisExtent = constraints.crossAxisExtent;

    final mainStride = layout.mainDashboardAxisStride;
    final crossStride = layout.crossDashboardAxisStride;
    final mainSpacing = layout.mainDashboardAxisSpacing;
    final crossSpacing = layout.crossDashboardAxisSpacing;
    // final totalCrossSlots = layout.maxCrossDashboardAxisSlots;

    final paint = Paint()
      ..color = const Color.fromARGB(184, 234, 5, 5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Lines parallel to the scroll axis — between dashboard main-axis slots.
    // These always span the full painted extent; no viewport culling needed.
    final parallelCount = mainDashboardAxisSlots - 1;

    if (parallelCount > 0) {
      final pts = Float32List(parallelCount * 4);
      for (int i = 1; i <= parallelCount; i++) {
        final crossDelta = i * mainStride - mainSpacing / 2;
        final p1 = originOffset + crossAxisUnit * crossDelta;
        final p2 = p1 + mainAxisUnit * paintExtent;
        final base = (i - 1) * 4;
        pts[base] = p1.dx;
        pts[base + 1] = p1.dy;
        pts[base + 2] = p2.dx;
        pts[base + 3] = p2.dy;
      }
      canvas.drawRawPoints(PointMode.lines, pts, paint);
    }

    // Lines perpendicular to the scroll axis — between dashboard cross-axis slots.
    // Only draw those whose scroll-space position falls inside the viewport.
    final firstSep = math.max(1, (scrollOffset / crossStride).floor());

    /// always fill the viewport with grid lines, even when the children do not fill the viewport.
    final lastSep = ((scrollOffset + paintExtent) / crossStride).ceil() + 1;
    final maxPerpCount = lastSep - firstSep + 1;

    if (maxPerpCount > 0) {
      final pts = Float32List(maxPerpCount * 4);
      int count = 0;
      for (int i = firstSep; i <= lastSep; i++) {
        // Centre the line in the gap between slot (i-1) and slot i.
        final scrollPos = i * crossStride - crossSpacing / 2;
        final mainDelta = scrollPos - scrollOffset;
        if (mainDelta < 0.0 || mainDelta > paintExtent) continue;

        final p1 = originOffset + mainAxisUnit * mainDelta;
        final p2 = p1 + crossAxisUnit * crossAxisExtent;
        final base = count * 4;
        pts[base] = p1.dx;
        pts[base + 1] = p1.dy;
        pts[base + 2] = p2.dx;
        pts[base + 3] = p2.dy;
        count++;
      }
      if (count > 0) {
        canvas.drawRawPoints(
          PointMode.lines,
          Float32List.sublistView(pts, 0, count * 4),
          paint,
        );
      }
    }
  }
}
