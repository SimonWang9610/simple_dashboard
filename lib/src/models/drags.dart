import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

class DragInfo {
  final LayoutItem item;
  final Size size;
  final Offset origin;
  final Widget feedback;
  final Offset localPosition;
  final Offset globalPosition;

  const DragInfo({
    required this.item,
    required this.size,
    required this.origin,
    required this.feedback,
    required this.localPosition,
    required this.globalPosition,
  });

  /// Compute the offset from the pointer to the center of the item,
  /// which will be used to keep the relative position between the pointer and the item during dragging.
  ///
  /// IT is used for [AutoScroll] to determine when to trigger auto-scrolling
  /// based on the dragging item's position relative to the viewport edges.
  ///
  /// the dragging item's position is computed by: the pointer local position in the viewport + this offset.
  Offset computeRelativeOffset([Alignment alignment = Alignment.center]) {
    final reference = alignment.alongSize(size);
    return reference - localPosition;
  }
}

class DraggingItemPosition extends Equatable {
  final double dx;
  final double dy;
  final Size size;

  const DraggingItemPosition({
    required this.dx,
    required this.dy,
    required this.size,
  });

  factory DraggingItemPosition.fromDragInfo(DragInfo info) {
    return DraggingItemPosition(
      dx: info.origin.dx,
      dy: info.origin.dy,
      size: info.size,
    );
  }

  DraggingItemPosition resize(ResizeDirection direction, Offset delta) {
    double newX = dx;
    double newY = dy;

    if (direction.isLeftEdge) {
      newX += delta.dx;
    }

    if (direction.isTopEdge) {
      newY += delta.dy;
    }

    final widthDelta =
      (direction.isRightEdge ? delta.dx : 0.0) -
      (direction.isLeftEdge ? delta.dx : 0.0);
    final heightDelta =
      (direction.isBottomEdge ? delta.dy : 0.0) -
      (direction.isTopEdge ? delta.dy : 0.0);

    return DraggingItemPosition(
      dx: newX,
      dy: newY,
      size: size + Offset(widthDelta, heightDelta),
    );
  }

  DraggingItemPosition move(Offset delta) {
    return DraggingItemPosition(
      dx: dx + delta.dx,
      dy: dy + delta.dy,
      size: size,
    );
  }

  @override
  List<Object?> get props => [dx, dy, size];

  @override
  bool get stringify => true;
}

class DraggingLayoutDelta {
  final int x;
  final int y;
  final Offset delta;

  const DraggingLayoutDelta({
    required this.x,
    required this.y,
    required this.delta,
  });

  @override
  String toString() {
    return "DraggingLayoutDelta(x: $x, y: $y, delta: $delta)";
  }
}
