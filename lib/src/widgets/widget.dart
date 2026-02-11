import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_delegate.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/widgets/render.dart';

class DashboardLayout extends ParentDataWidget<DashboardItemParentData> {
  final LayoutRect rect;

  const DashboardLayout({
    super.key,
    required this.rect,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as DashboardItemParentData;
    if (parentData.layout != rect) {
      parentData.layout = rect;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => RawDashboard;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LayoutRect>('rect', rect));
  }
}

class RawDashboard extends MultiChildRenderObjectWidget {
  final DashboardLayoutDelegate layoutDelegate;
  final int mainAxisSlots;
  final DashboardAxis axis;

  const RawDashboard({
    super.key,
    required this.layoutDelegate,
    required this.mainAxisSlots,
    required this.axis,
    super.children,
  });

  @override
  RenderDashboard createRenderObject(BuildContext context) {
    return RenderDashboard(
      layoutDelegate: layoutDelegate,
      axis: axis,
      mainAxisSlots: mainAxisSlots,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderDashboard renderObject) {
    renderObject
      ..axis = axis
      ..mainAxisSlots = mainAxisSlots
      ..layoutDelegate = layoutDelegate;
  }
}
