import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/classes/resizer.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/sliver/widgets.dart';

class ResizableItemWidget extends StatefulWidget with LayoutItemWidget {
  @override
  final LayoutItem item;
  final double edgeThreshold;
  final DashboardResizer resizer;
  final Widget child;

  const ResizableItemWidget({
    super.key,
    required this.item,
    required this.resizer,
    this.edgeThreshold = 10.0,
    required this.child,
  });

  @override
  State<ResizableItemWidget> createState() => _ResizableItemWidgetState();
}

class _ResizableItemWidgetState extends State<ResizableItemWidget> {
  MouseCursor _cursor = MouseCursor.defer;
  ResizeDirection? _resizeDirection;

  @override
  void didUpdateWidget(covariant ResizableItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _cursor,
      onEnter: (_) => _computeEdgeRects(),
      onExit: (_) => _reset(),
      onHover: (event) => _update(event.localPosition),
      child: GestureDetector(
        onPanStart: (details) {
          if (_resizeDirection != null) {
            widget.resizer.startResize(_resizeDirection!, widget.item);
          }
        },
        onPanUpdate: (details) {
          widget.resizer.updateResize(details.localPosition, details.delta);
        },
        onPanEnd: (details) {
          widget.resizer.endResize(true);
        },
        onPanCancel: () {
          widget.resizer.endResize(false);
        },
        child: widget.child,
      ),
    );
  }

  Map<ResizeDirection, Rect> _edgeRects = {};

  void _computeEdgeRects() {
    final size = context.size;
    if (size == null) return;
    _edgeRects = size.computeEdgeRects(widget.edgeThreshold);
  }

  void _reset() {
    _resizeDirection = null;

    if (_cursor != MouseCursor.defer) {
      setState(() {
        _cursor = MouseCursor.defer;
      });
    }
  }

  void _update(Offset localPosition) {
    if (_edgeRects.isEmpty) return;

    ResizeDirection? newDirection;
    MouseCursor newCursor = MouseCursor.defer;

    for (final entry in _edgeRects.entries) {
      if (entry.value.contains(localPosition)) {
        newDirection = entry.key;

        newCursor = switch (entry.key) {
          ResizeDirection.left ||
          ResizeDirection.right => SystemMouseCursors.resizeColumn,
          ResizeDirection.up ||
          ResizeDirection.down => SystemMouseCursors.resizeRow,
          _ => SystemMouseCursors.move,
        };
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
