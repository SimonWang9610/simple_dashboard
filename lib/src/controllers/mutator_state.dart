import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

mixin DashboardMutatingStateMixin<T extends StatefulWidget> on State<T> {
  DashboardItemMutator? get mutator;
  AutoScroll? get autoScroll;

  MoveDropStrategy get moveDropStrategy;

  RenderBox? get viewport {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject;
    }
    return null;
  }

  DragInfo? _dragInfo;
  bool _isDragging = false;

  void absorbPointer(PointerDownEvent event, DragInfo dragInfo) {
    if (_isDragging) {
      return;
    }

    _dragInfo = dragInfo;

    // _resizerRecognizer.addPointer(event);
    _dragRecognizer.addPointer(event);
  }

  DashboardMetricsManager get metrics;

  late final _dragRecognizer = DelayedMultiDragGestureRecognizer()
    ..onStart = _onMoveDragStart;

  ItemDrag? _onMoveDragStart(Offset globalPosition) {
    if (_isDragging) return null;

    _isDragging = true;

    assert(_dragInfo != null);
    assert(_resizeDrag == null);

    final themeData = Theme.of(context);

    return ItemDrag.move(
      initialPosition: globalPosition,
      dragInfo: _dragInfo!,
      mutator: mutator!,
      overlayState: Overlay.of(context),
      viewport: viewport!,
      strategy: moveDropStrategy,
      metrics: metrics,
      autoScroll: autoScroll,
      onDragEnd: () {
        _isDragging = false;
      },
      builder: (context, dragInfo, delta) {
        return ValueListenableBuilder(
          valueListenable: delta,
          builder: (_, delta, feedback) {
            return Positioned(
              left: dragInfo.origin.dx + delta.dx,
              top: dragInfo.origin.dy + delta.dy,
              child: Material(
                child: feedback!,
              ),
            );
          },
          child: Theme(
            data: themeData,
            child: Material(
              child: SizedBox.fromSize(
                size: dragInfo.size,
                child: dragInfo.feedback,
              ),
            ),
          ),
        );
      },
    );
  }

  ItemDrag? _resizeDrag;
  ResizeDirection? _resizeDirection;

  late final _resizerRecognizer = PanGestureRecognizer()
    ..onStart = _onResizeDragStart
    ..onUpdate = (details) {
      _resizeDrag?.update(details);
    }
    ..onEnd = (details) {
      _resizeDrag?.end(details);
      _resizeDrag = null;
    }
    ..onCancel = () {
      _resizeDrag?.cancel();
      _resizeDrag = null;
    };

  void _onResizeDragStart(DragStartDetails details) {
    if (_isDragging) return;

    assert(_resizeDrag == null);
    assert(_dragInfo != null);

    final themeData = Theme.of(context);

    _resizeDrag = ItemDrag.resize(
      dragInfo: _dragInfo!,
      mutator: mutator!,
      overlayState: Overlay.of(context),
      viewport: viewport!,
      direction: _resizeDirection!,
      autoScroll: autoScroll,
      onDragEnd: () {
        _isDragging = false;
      },
      builder: (context, dragInfo, delta) {
        return Positioned(
          left: dragInfo.origin.dx,
          top: dragInfo.origin.dy,
          child: Theme(
            data: themeData,
            child: Material(
              child: ValueListenableBuilder(
                valueListenable: delta,
                builder: (_, delta, _) {
                  return SizedBox.fromSize(
                    size: dragInfo.size + delta,
                    child: dragInfo.feedback,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _isDragging = false;
    _dragInfo = null;
    _resizeDrag?.cancel();

    _resizerRecognizer.dispose();
    _dragRecognizer.dispose();
    super.dispose();
  }
}
