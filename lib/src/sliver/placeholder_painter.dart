import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

class DashboardPlaceholderPainter extends Listenable {
  final ValueListenable<LayoutPlaceholder?>? _placeholder;

  const DashboardPlaceholderPainter(this._placeholder);

  @override
  void addListener(VoidCallback listener) =>
      _placeholder?.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _placeholder?.removeListener(listener);

  void paint(
    Canvas canvas,
    SliverDashboardLayout layout,
    SliverConstraints constraints,
  ) {
    if (_placeholder?.value == null) return;

    final placeholder = _placeholder!.value!;

    final placeholderGeometry = layout.computeItemGeometry(placeholder.rect);

    final placeholderBox = placeholderGeometry.getBoxItemGeometry(
      layout.dashboardAxis,
      dashboardScrollOffset: constraints.scrollOffset,
    );

    final mainAxisDelta = switch (layout.dashboardAxis) {
      DashboardAxis.horizontal => placeholderBox.size.height,
      DashboardAxis.vertical => placeholderBox.size.width,
    };

    if (mainAxisDelta < constraints.remainingPaintExtent &&
        mainAxisDelta + placeholderGeometry.mainAxisExtent > 0) {
      canvas.drawRect(
        placeholderBox.rect,
        Paint()
          ..color = const Color(0x88000000)
          ..style = PaintingStyle.fill,
      );
    }
  }
}
