import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/classes/dragger.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
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

  final DashboardDragger dragger;

  /// The widget displayed in the dashboard while dragging.  Defaults to a
  /// 30 % opacity copy of [child].
  final Widget? childWhenDragging;

  /// The widget that follows the pointer during the drag.  Defaults to a
  /// 75 % opacity copy of [child] wrapped in a [Material] (so it is painted
  /// on top of everything).
  final Widget Function(BuildContext context, LayoutItem item)? feedbackBuilder;

  /// Pixels from the viewport edge at which auto-scrolling kicks in.
  final double autoScrollEdgeThreshold;

  /// Pixels per frame scrolled during auto-scroll.
  final double autoScrollSpeed;

  final Widget child;

  const DraggableItemWidget({
    super.key,
    required this.item,
    required this.dragger,
    required this.child,
    this.childWhenDragging,
    this.feedbackBuilder,
    this.autoScrollEdgeThreshold = 50.0,
    this.autoScrollSpeed = 10.0,
  });

  @override
  State<DraggableItemWidget> createState() => _DraggableItemWidgetState();
}

class _DraggableItemWidgetState extends State<DraggableItemWidget> {
  Timer? _autoScrollTimer;

  Size? _childSize;

  final _cacheKey = GlobalKey();

  @override
  void dispose() {
    _stopAutoScroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final whenDragging =
        widget.childWhenDragging ??
        ColoredBox(color: const Color(0xFF000000).withOpacity(0.3));

    final keyedChild = KeyedSubtree(
      key: _cacheKey,
      child: widget.child,
    );

    return LongPressDraggable<LayoutItem>(
      data: widget.item,
      feedback: SizedBox.fromSize(
        size: _childSize,
        child: Material(
          color: const Color(0xFF000000).withOpacity(0.75),
          child: keyedChild,
        ),
      ),
      childWhenDragging: whenDragging,
      onDragStarted: () {
        final size = context.size ?? Size.zero;
        widget.dragger.startDrag(widget.item, size);
        _childSize = size;
      },
      onDragUpdate: (details) {
        widget.dragger.updateDrag(details.delta);
        _maybeAutoScroll(details.globalPosition);
      },
      onDragEnd: (details) {
        _stopAutoScroll();
        widget.dragger.endDrag(true);
      },
      onDraggableCanceled: (velocity, offset) {
        _stopAutoScroll();
        widget.dragger.endDrag(false);
      },
      child: keyedChild,
    );
  }

  // ---------------------------------------------------------------------------
  // Auto-scroll
  // ---------------------------------------------------------------------------

  void _maybeAutoScroll(Offset globalPosition) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      _stopAutoScroll();
      return;
    }

    final viewportRO = scrollable.context.findRenderObject();
    if (viewportRO == null) {
      _stopAutoScroll();
      return;
    }

    // Convert global position to viewport-local coordinates.
    final transform = viewportRO.getTransformTo(null);
    // getTransformTo(null) gives transform from this RO to screen.
    // We want the inverse to go from screen → RO.
    final inverted = Matrix4.inverted(transform);
    final localInViewport = MatrixUtils.transformPoint(
      inverted,
      globalPosition,
    );

    final viewportBounds = viewportRO.paintBounds;
    final scrollAxis = scrollable.widget.axis;
    double? scrollDir;

    if (scrollAxis == Axis.vertical) {
      if (localInViewport.dy < widget.autoScrollEdgeThreshold) {
        scrollDir = -1.0;
      } else if (localInViewport.dy >
          viewportBounds.height - widget.autoScrollEdgeThreshold) {
        scrollDir = 1.0;
      }
    } else {
      if (localInViewport.dx < widget.autoScrollEdgeThreshold) {
        scrollDir = -1.0;
      } else if (localInViewport.dx >
          viewportBounds.width - widget.autoScrollEdgeThreshold) {
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
    if (_autoScrollTimer != null) return;
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
