import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/classes/move_drag_handler.dart';
import 'package:simple_dashboard/src/classes/resize_drag_handler.dart';

abstract interface class DashboardItemMutator {
  List<LayoutItem> get items;
  void updateItems(List<LayoutItem> newItems);

  bool validateLayoutRect(LayoutRect rect);
}

/// A [Drag] that represents the dragging of a dashboard item, either moving or resizing.
///
/// It is responsible for managing the drag state, computing the dragging item's position,
/// and updating the layout accordingly.
///
/// However, it delegates to [DragLayoutHandler] for the specific logic of how to update the layout during dragging
///
/// See also:
///   - [MoveDragHandler]: a handler for moving items.
///   - [ResizeDragHandler]: a handler for resizing items.
class ItemDrag extends Drag {
  final OverlayState overlayState;
  final DragInfo dragInfo;
  final AutoScroll? autoScroll;
  final RenderBox viewport;
  late final Offset distanceFromPointerToItemCenter;

  /// The accumulated delta since the start of dragging,
  /// which would be used to compute the relative shift of [LayoutItem]s during dragging.
  late final ValueNotifier<DraggingItemPosition> _position;

  /// The overlay entry that displays the dragging feedback widget.
  late final OverlayEntry _entry;

  /// The feedback builder for the dragging item,
  /// which would be displayed in the overlay during dragging.
  final DraggingItemFeedbackBuilder builder;

  /// The extent of each slot in the main axis,
  /// which is used to compute how many slots the dragging item has shifted during dragging.
  late final double dragSlotExtentX;

  /// The extent of each slot in the cross axis,
  /// which is used to compute how many slots the dragging item has shifted during dragging.
  late final double dragSlotExtentY;

  /// The callback when the drag ends, which can be used to trigger additional actions after dragging.
  final VoidCallback? onDragEnd;

  final DragLayoutHandler handler;

  factory ItemDrag.move({
    required DragInfo dragInfo,
    required OverlayState overlayState,
    required RenderBox viewport,
    required DraggingItemFeedbackBuilder builder,
    required DashboardItemMutator mutator,
    required MoveDropStrategy strategy,
    required DashboardMetricsManager metrics,
    required Offset initialPosition,
    bool synthesizedEnd = true,
    VoidCallback? onDragEnd,
    AutoScroll? autoScroll,
  }) {
    return ItemDrag(
      dragInfo: dragInfo,
      overlayState: overlayState,
      viewport: viewport,
      builder: builder,
      onDragEnd: onDragEnd,
      autoScroll: autoScroll,
      handler: MoveDragHandler(
        strategy: strategy,
        metrics: metrics,
        initialPosition: initialPosition,
        draggingItem: dragInfo.item,
        mutator: mutator,
        synthesizedEnd: synthesizedEnd,
        initialDraggingPosition: DraggingItemPosition.fromDragInfo(dragInfo),
      ),
    );
  }

  factory ItemDrag.resize({
    required DragInfo dragInfo,
    required OverlayState overlayState,
    required RenderBox viewport,
    required DraggingItemFeedbackBuilder builder,
    required ResizeDirection direction,
    required DashboardItemMutator mutator,
    VoidCallback? onDragEnd,
    AutoScroll? autoScroll,
  }) {
    return ItemDrag(
      dragInfo: dragInfo,
      overlayState: overlayState,
      viewport: viewport,
      builder: builder,
      onDragEnd: onDragEnd,
      autoScroll: autoScroll,
      handler: ResizeDragHandler(
        direction: direction,
        draggingItem: dragInfo.item,
        mutator: mutator,
        initialDraggingPosition: DraggingItemPosition.fromDragInfo(dragInfo),
      ),
    );
  }

  ItemDrag({
    required this.dragInfo,
    required this.overlayState,
    required this.viewport,
    required this.builder,
    this.onDragEnd,
    this.autoScroll,
    required this.handler,
  }) {
    _position = ValueNotifier<DraggingItemPosition>(
      handler.updatePosition(Offset.zero, Offset.zero),
    );

    /// relative distance between the start pointer and the item position.
    distanceFromPointerToItemCenter = dragInfo.computeRelativeOffset();

    dragSlotExtentX = dragInfo.size.width > 0
        ? dragInfo.size.width / dragInfo.item.rect.size.width
        : 1.0;
    dragSlotExtentY = dragInfo.size.height > 0
        ? dragInfo.size.height / dragInfo.item.rect.size.height
        : 1.0;

    handler.startDragging();

    _entry = OverlayEntry(
      builder: (context) => builder(context, _position, dragInfo.feedback),
    );

    overlayState.insert(_entry);

    final result = _computePointerInViewport(dragInfo.origin);

    autoScroll?.start(result.$1, result.$2);
  }

  Offset _accumulatedDelta = Offset.zero;

  /// TODO: should remove placeholder when the pointer moves out of the original item boundary,
  /// instead of waiting until the drag ends?
  @override
  void update(DragUpdateDetails details) {
    final accumulated = _accumulatedDelta + details.delta;

    final dx = (accumulated.dx / dragSlotExtentX).round();
    final dy = (accumulated.dy / dragSlotExtentY).round();

    final updated = handler.updateDragging(dx, dy);

    if (updated) {
      _accumulatedDelta = accumulated;
      _position.value = handler.updatePosition(accumulated, details.delta);
    }

    final result = _computePointerInViewport(details.globalPosition);

    autoScroll?.start(result.$1, result.$2);
  }

  @override
  void end(DragEndDetails details) {
    final synthesized = handler.synthesize(
      details,
      _accumulatedDelta,
    );

    final accepted = isPointerInViewport(synthesized.globalPosition);

    handler.finishDragging(accepted);
    _dispose();
    autoScroll?.stop();
    onDragEnd?.call();
  }

  @override
  void cancel() {
    handler.finishDragging(false);
    _dispose();
    autoScroll?.stop();
    onDragEnd?.call();
  }

  /// compute the local position relative to the viewport based on the given global position,
  /// and return it with the viewport size
  (Size, Offset) _computePointerInViewport(Offset globalPosition) {
    final localPointerPosition = viewport.globalToLocal(globalPosition);

    return (
      viewport.size,

      /// transform the global position to the local position in the viewport,
      ///  and add the distance from the pointer to the item center.
      ///
      /// For example, if [distanceFromPointerToItemCenter] si relative to the item center,
      /// so users can know when the center of dragging item reaches the edge of the viewport to trigger auto-scrolling,
      /// instead of relying on a very dynamic start pointer position.
      localPointerPosition + distanceFromPointerToItemCenter,
    );
  }

  /// TODO: consider velocity to determine whether the pointer is out of viewport
  bool isPointerInViewport(Offset globalPosition, {double? velocity}) {
    final pointerPosition = _computePointerInViewport(globalPosition).$2;
    final viewportRect = Offset.zero & viewport.size;

    return viewportRect.contains(pointerPosition);
  }

  void _dispose() {
    _position.dispose();
    _entry.remove();
    _entry.dispose();
    autoScroll?.stop();
  }
}

abstract base class DragLayoutHandler {
  final DashboardItemMutator mutator;
  final LayoutItem draggingItem;
  final DraggingItemPosition initialDraggingPosition;

  const DragLayoutHandler({
    required this.mutator,
    required this.draggingItem,
    required this.initialDraggingPosition,
  });

  void startDragging();

  /// Update the layout based on the dragging delta, and return whether the layout is updated.
  /// The return value is used to determine whether to update the dragging position
  bool updateDragging(int dx, int dy);
  void finishDragging(bool accepted);

  DraggingItemPosition updatePosition(Offset accumulated, Offset delta);

  DragEndDetails synthesize(
    DragEndDetails details,
    Offset accumulated,
  ) => details;
}
