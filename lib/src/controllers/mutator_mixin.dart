import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

mixin DashboardMutatorStateMixin<T extends StatefulWidget> on State<T> {
  DashboardItemMutator? getDashboardMutator();
  AutoScroll get autoScroll;

  DashboardMutatorDelegate get mutatorDelegate;

  RenderBox? get viewport {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject;
    }
    return null;
  }

  DashboardItemMutator? _mutator;

  late final _dragGestureRecognizer = PanGestureRecognizer()
    ..onStart = _onDragStart
    ..onUpdate = _onDragUpdate
    ..onEnd = _onDragEnd
    ..onCancel = () => _endDrag(false);

  DragInfo? _dragInfo;
  OverlayEntry? _draggingOverlay;
  ValueNotifier<Offset>? _draggingGlobalOrigin;

  void absorbPointer(PointerDownEvent event, DragInfo dragInfo) {
    _mutator ??= getDashboardMutator();

    if (_dragInfo != null || _mutator == null) return;

    _dragGestureRecognizer.addPointer(event);
    _dragInfo = dragInfo;
  }

  void _onDragStart(DragStartDetails details) {
    assert(_dragInfo != null);
    assert(_draggingOverlay == null);

    _mutator?.startMutation(_dragInfo!, mutatorDelegate);

    _draggingGlobalOrigin?.dispose();
    _draggingGlobalOrigin = ValueNotifier(_dragInfo!.origin);

    final themeData = Theme.of(context);

    _draggingOverlay = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder(
          valueListenable: _draggingGlobalOrigin!,
          builder: (context, value, child) {
            return Positioned(
              left: value.dx,
              top: value.dy,
              child: child!,
            );
          },
          child: Theme(
            data: themeData,
            child: Material(
              child: SizedBox.fromSize(
                size: _dragInfo!.size,
                child: _dragInfo!.feedback,
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_draggingOverlay!);

    /// the local position is relative to the item size,
    /// so we need to compute the distance from the pointer to the item center,
    /// and use it to compute the item center position relative to the viewport during dragging
    /// to achieve better auto scroll experience
    _pointerToItemCenter =
        _dragInfo!.size.center(Offset.zero) - details.localPosition;

    final result = _computePointerPosition(details.globalPosition);

    if (result != null) {
      autoScroll.start(result.$1, result.$2);
    } else {
      autoScroll.stop();
    }
  }

  /// the relative distance between the start pointer local position and the item center,
  /// used to compute the item center position during dragging for better auto scroll experience
  Offset? _pointerToItemCenter;

  /// compute the local position relative to the viewport based on the given global position,
  /// and return it with the viewport size
  (Size, Offset)? _computePointerPosition(Offset globalPosition) {
    final box = viewport;

    if (box == null) return null;

    final localPointerPosition = box.globalToLocal(globalPosition);

    final Offset position;

    /// if we have the distance from the pointer to the item center,
    /// we compute the item center position,
    if (_pointerToItemCenter != null) {
      position = localPointerPosition + _pointerToItemCenter!;
    } else {
      position = localPointerPosition;
    }

    return (box.size, position);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_draggingGlobalOrigin != null) {
      _draggingGlobalOrigin!.value += details.delta;
    }

    _mutator?.updateMutation(details.delta);

    final result = _computePointerPosition(details.globalPosition);

    if (result != null) {
      autoScroll.start(result.$1, result.$2);
    } else {
      autoScroll.stop();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final bool confirmed;
    final box = viewport;

    if (box == null) {
      confirmed = false;
    } else {
      final pointerPosition = box.globalToLocal(details.globalPosition);
      final viewportRect = Offset.zero & box.size;

      confirmed = viewportRect.contains(pointerPosition);
    }

    _endDrag(confirmed);
  }

  void _endDrag(bool confirmed) {
    _mutator?.endMutation(confirmed);
    _dragInfo = null;
    _draggingOverlay?.remove();
    _draggingOverlay = null;
    _draggingGlobalOrigin?.dispose();
    _draggingGlobalOrigin = null;

    /// === clean up auto scroll state ===
    autoScroll.stop();
    _pointerToItemCenter = null;
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newMutator = getDashboardMutator();

    if (newMutator != _mutator) {
      _endDrag(false);
      _mutator = newMutator;
    }
  }

  @override
  void dispose() {
    _endDrag(false);
    _dragGestureRecognizer.dispose();
    super.dispose();
  }
}
