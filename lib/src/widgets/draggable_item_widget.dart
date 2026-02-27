import 'package:flutter/material.dart';
import 'package:simple_dashboard/src/classes/dragger.dart';
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
class DraggableItemWidget extends StatelessWidget with LayoutItemWidget {
  @override
  final LayoutItem item;

  final Widget child;

  const DraggableItemWidget({
    super.key,
    required this.item,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (item is ItemPlaceholder) {
      return ColoredBox(color: Colors.red);
    }

    final cacheKey = Dashboard.getCacheKeyForItem(context, item.id);

    final keyedChild = KeyedSubtree(
      key: cacheKey,
      child: child,
    );

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        final box = context.findRenderObject() as RenderBox?;
        final dashboard = Dashboard.of(context);

        if (box == null || dashboard == null) return;
        final itemOrigin = box.localToGlobal(box.size.topLeft(Offset.zero));

        dashboard.absorbPointer(
          event,
          DragInfo(
            item: item,
            feedback: keyedChild,
            size: box.size,
            origin: itemOrigin,
          ),
        );
      },
      child: keyedChild,
    );
  }
}
