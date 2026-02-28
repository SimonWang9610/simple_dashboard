import 'package:flutter/material.dart';
import 'package:simple_dashboard/src/classes/drags.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/sliver/dashboard.dart';
import 'package:simple_dashboard/src/sliver/widgets.dart';

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
    if (item.id is PlaceholderId) {
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
            localPosition: event.localPosition,
          ),
        );
      },
      child: keyedChild,
    );
  }
}
