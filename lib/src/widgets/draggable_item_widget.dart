import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/classes/drags.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/sliver/widgets.dart';
import 'package:simple_dashboard/src/utils/extensions.dart';
import 'package:simple_dashboard/src/widgets/cache_key_store.dart';

class DraggableItemWidget extends StatefulWidget with LayoutItemWidget {
  @override
  final LayoutItem item;

  final double edgeThreshold;

  final Widget child;

  const DraggableItemWidget({
    super.key,
    required this.item,
    this.edgeThreshold = 10.0,
    required this.child,
  });

  @override
  State<DraggableItemWidget> createState() => _DraggableItemWidgetState();
}

class _DraggableItemWidgetState extends State<DraggableItemWidget>
    with LayoutItemResizeState {
  @override
  double get edgeThreshold => widget.edgeThreshold;

  @override
  Widget build(BuildContext context) {
    if (widget.item.id is PlaceholderId) {
      return ColoredBox(color: Colors.red);
    }

    final cacheKey = ItemCacheKeyStore.getCacheKeyForItem(
      context,
      widget.item.id,
    );

    final keyedChild = KeyedSubtree(
      key: cacheKey,
      child: widget.child,
    );

    return MouseRegion(
      cursor: _cursor,
      onEnter: (_) => computeEdgeRects(),
      onExit: (_) => reset(),
      onHover: (event) => updateResizeDirection(event.localPosition),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          final box = context.findRenderObject() as RenderBox?;
          final mutator = context.ofDashboardMutator();

          if (box == null || mutator == null) return;

          final itemOrigin = box.localToGlobal(box.size.topLeft(Offset.zero));

          mutator.absorbPointer(
            event,
            DragInfo(
              item: widget.item,
              feedback: keyedChild,
              size: box.size,
              origin: itemOrigin,
              localPosition: event.localPosition,
              globalPosition: event.position,
            ),
            resizeDirection: _resizeDirection,
          );
        },
        child: keyedChild,
      ),
    );
  }
}

mixin LayoutItemResizeState<T extends StatefulWidget> on State<T> {
  double get edgeThreshold;

  MouseCursor _cursor = MouseCursor.defer;
  ResizeDirection? _resizeDirection;
  Map<ResizeDirection, Rect> _edgeRects = {};

  void computeEdgeRects() {
    final size = context.size;
    if (size == null) return;
    _edgeRects = size.computeEdgeRects(edgeThreshold);
  }

  void reset() {
    _resizeDirection = null;
    _edgeRects = {};

    if (_cursor != MouseCursor.defer) {
      setState(() {
        _cursor = MouseCursor.defer;
      });
    }
  }

  void updateResizeDirection(Offset localPosition) {
    if (_edgeRects.isEmpty) computeEdgeRects();
    if (_edgeRects.isEmpty) return;

    ResizeDirection? newDirection;
    MouseCursor newCursor = MouseCursor.defer;

    for (final entry in _edgeRects.entries) {
      if (entry.value.contains(localPosition)) {
        newDirection = entry.key;
        newCursor = entry.key.cursor;
        break;
      }
    }

    _resizeDirection = newDirection;

    if (newCursor != _cursor) {
      setState(() {
        _cursor = newCursor;
      });
    }
  }
}

extension on Size {
  Map<ResizeDirection, Rect> computeEdgeRects(double edgeThreshold) {
    return {
      ResizeDirection.topLeft: Rect.fromLTWH(
        0,
        0,
        edgeThreshold,
        edgeThreshold,
      ),
      ResizeDirection.topRight: Rect.fromLTWH(
        width - edgeThreshold,
        0,
        edgeThreshold,
        edgeThreshold,
      ),
      ResizeDirection.bottomLeft: Rect.fromLTWH(
        0,
        height - edgeThreshold,
        edgeThreshold,
        edgeThreshold,
      ),
      ResizeDirection.bottomRight: Rect.fromLTWH(
        width - edgeThreshold,
        height - edgeThreshold,
        edgeThreshold,
        edgeThreshold,
      ),
      ResizeDirection.left: Rect.fromLTWH(
        0,
        edgeThreshold,
        edgeThreshold,
        height - 2 * edgeThreshold,
      ),
      ResizeDirection.right: Rect.fromLTWH(
        width - edgeThreshold,
        edgeThreshold,
        edgeThreshold,
        height - 2 * edgeThreshold,
      ),
      ResizeDirection.up: Rect.fromLTWH(
        edgeThreshold,
        0,
        width - 2 * edgeThreshold,
        edgeThreshold,
      ),
      ResizeDirection.down: Rect.fromLTWH(
        edgeThreshold,
        height - edgeThreshold,
        width - 2 * edgeThreshold,
        edgeThreshold,
      ),
    };
  }
}
