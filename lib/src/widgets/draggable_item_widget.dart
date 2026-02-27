import 'package:flutter/material.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/sliver/dashboard.dart';
import 'package:simple_dashboard/src/sliver/widgets.dart';

/// A widget that wraps a dashboard item and makes it draggable.
///
/// Use a **long-press** to initiate a drag.  While dragging, a semi-transparent
/// [feedback] widget follows the finger/cursor, and the dashboard's placeholder
/// painter shows where the item will be dropped.
///
/// Combine with [ResizableItemWidget] when both resize and drag are needed:
/// ```dart
/// DraggableItemWidget(
///   item: item,
///   dragger: controller,
///   child: ResizableItemWidget(
///     item: item,
///     resizer: controller,
///     child: MyItemContent(item: item),
///   ),
/// )
/// ```
class DraggableItemWidget extends StatefulWidget with LayoutItemWidget {
  @override
  final LayoutItem item;

  final Widget child;

  const DraggableItemWidget({
    super.key,
    required this.item,
    required this.child,
  });

  @override
  State<DraggableItemWidget> createState() => _DraggableItemWidgetState();
}

class _DraggableItemWidgetState extends State<DraggableItemWidget> {
  final _cacheKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (widget.item is LayoutPlaceholder) {
      return ColoredBox(color: Colors.red);
    }

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final itemOrigin = box.localToGlobal(box.size.topLeft(Offset.zero));
        final dashboard = context.findAncestorStateOfType<DashboardState>();
        dashboard?.routePointerEvent(
          details,
          DragInfo(
            item: widget.item,
            itemKey: _cacheKey,
            size: box.size,
            origin: itemOrigin,
          ),
        );
      },
      child: KeyedSubtree(
        key: _cacheKey,
        child: widget.child,
      ),
    );
  }
}
