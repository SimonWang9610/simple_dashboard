import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

class ResizableItemWidget extends StatefulWidget with LayoutItemWidget {
  @override
  final LayoutItem item;
  final double edgeThreshold;
  final Widget child;

  /// Pixels from the viewport edge at which auto-scrolling kicks in.
  final double autoScrollEdgeThreshold;

  /// Pixels per frame scrolled during auto-scroll (at 60 fps ≈ 10 px/frame).
  final double autoScrollSpeed;

  const ResizableItemWidget({
    super.key,
    required this.item,
    this.edgeThreshold = 10.0,
    this.autoScrollEdgeThreshold = 50.0,
    this.autoScrollSpeed = 10.0,
    required this.child,
  });

  @override
  State<ResizableItemWidget> createState() => _ResizableItemWidgetState();
}

class _ResizableItemWidgetState extends State<ResizableItemWidget> {
  MouseCursor _cursor = MouseCursor.defer;
  ResizeDirection? _resizeDirection;
  bool _isResizing = false;

  // Auto-scroll
  Timer? _autoScrollTimer;

  @override
  void didUpdateWidget(covariant ResizableItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isResizing) _reset();
  }

  @override
  void dispose() {
    _stopAutoScroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _cursor,
      onEnter: (_) => _computeEdgeRects(),
      onExit: (_) {
        if (!_isResizing) _reset();
      },
      onHover: (event) => _update(event.localPosition),
      child: GestureDetector(
        onPanStart: (details) {
          if (_resizeDirection != null) {
            // final size = context.size ?? Size.zero;
            // widget.resizer.startResize(_resizeDirection!, widget.item, size);
            _isResizing = true;
          }
        },
        onPanUpdate: (details) {
          if (_isResizing) {
            // widget.resizer.updateResize(
            //   details.localPosition,
            //   details.delta,
            // );
            _maybeAutoScroll(details.localPosition);
          }
        },
        onPanEnd: (details) {
          _stopAutoScroll();
          // widget.resizer.endResize(true);
          _isResizing = false;
          _reset();
        },
        onPanCancel: () {
          _stopAutoScroll();
          // widget.resizer.endResize(false);
          _isResizing = false;
          _reset();
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
    _edgeRects = {};

    if (_cursor != MouseCursor.defer) {
      setState(() {
        _cursor = MouseCursor.defer;
      });
    }
  }

  void _update(Offset localPosition) {
    if (_edgeRects.isEmpty) _computeEdgeRects();
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

  // ---------------------------------------------------------------------------
  // Auto-scroll
  // ---------------------------------------------------------------------------

  void _maybeAutoScroll(Offset localPosition) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      _stopAutoScroll();
      return;
    }

    final renderObject = context.findRenderObject();
    final viewportRenderObject = scrollable.context.findRenderObject();
    if (renderObject == null || viewportRenderObject == null) {
      _stopAutoScroll();
      return;
    }

    // Convert local position to viewport coordinates.
    final transform = renderObject.getTransformTo(viewportRenderObject);
    final globalInViewport = MatrixUtils.transformPoint(
      transform,
      localPosition,
    );

    final viewportSize = viewportRenderObject.paintBounds;
    final scrollAxis = scrollable.widget.axis;
    double? scrollDir;

    if (scrollAxis == Axis.vertical) {
      if (globalInViewport.dy < widget.autoScrollEdgeThreshold) {
        scrollDir = -1.0;
      } else if (globalInViewport.dy >
          viewportSize.height - widget.autoScrollEdgeThreshold) {
        scrollDir = 1.0;
      }
    } else {
      if (globalInViewport.dx < widget.autoScrollEdgeThreshold) {
        scrollDir = -1.0;
      } else if (globalInViewport.dx >
          viewportSize.width - widget.autoScrollEdgeThreshold) {
        scrollDir = 1.0;
      }
    }

    if (scrollDir == null) {
      _stopAutoScroll();
    } else {
      _startAutoScroll(scrollDir, scrollable.position);
    }
  }

  void _startAutoScroll(double direction, ScrollPosition position) {
    if (_autoScrollTimer != null) return; // already running
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) {
        final newPixels = (position.pixels + direction * widget.autoScrollSpeed)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
        position.jumpTo(newPixels);
      },
    );
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
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
