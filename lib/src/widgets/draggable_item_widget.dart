import 'package:flutter/material.dart';
import 'package:simple_dashboard/src/classes/drags.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/sliver/widgets.dart';
import 'package:simple_dashboard/src/utils/extensions.dart';
import 'package:simple_dashboard/src/widgets/cache_key_store.dart';

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

    final cacheKey = ItemCacheKeyStore.getCacheKeyForItem(context, item.id);

    final keyedChild = KeyedSubtree(
      key: cacheKey,
      child: child,
    );

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        final box = context.findRenderObject() as RenderBox?;
        final mutator = context.ofDashboardMutator();

        if (box == null || mutator == null) return;

        final itemOrigin = box.localToGlobal(box.size.topLeft(Offset.zero));

        mutator.absorbPointer(
          event,
          DragInfo(
            item: item,
            feedback: keyedChild,
            size: box.size,
            origin: itemOrigin,
            localPosition: event.localPosition,
            globalPosition: event.position,
          ),
        );
      },
      child: keyedChild,
    );
  }
}
