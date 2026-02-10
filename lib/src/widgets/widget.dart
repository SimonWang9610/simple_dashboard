import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';
import 'package:simple_dashboard/src/widgets/controller.dart';
import 'package:simple_dashboard/src/widgets/render.dart';

class DashboardItemDataWidget
    extends ParentDataWidget<DashboardItemParentData> {
  final ItemRect rect;

  const DashboardItemDataWidget({
    super.key,
    required this.rect,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as DashboardItemParentData;
    if (parentData.rect != rect) {
      parentData.rect = rect;

      renderObject.parent?.markNeedsLayout();
    }

    Positioned(child: child);
  }

  @override
  Type get debugTypicalAncestorWidgetClass => RawDashboard;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ItemRect>('rect', rect));
  }
}

class RawDashboard extends MultiChildRenderObjectWidget {
  final DashboardLayoutNotifier layoutNotifier;

  const RawDashboard({
    super.key,
    required this.layoutNotifier,
    super.children,
  });

  @override
  RenderDashboard createRenderObject(BuildContext context) {
    return RenderDashboard(
      layoutNotifier: layoutNotifier,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderDashboard renderObject) {
    renderObject.layoutNotifier = layoutNotifier;
  }
}
