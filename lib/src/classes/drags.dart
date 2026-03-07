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

  final double acceptEdgeTolerance;

  factory ItemDrag.move({
    required DragInfo dragInfo,
    required OverlayState overlayState,
    required RenderBox viewport,
    required DraggingItemFeedbackBuilder builder,
    required DashboardItemMutator mutator,
    required MoveDropStrategy strategy,
    required DashboardMetricsManager metrics,
    required Offset initialPosition,
    double acceptEdgeTolerance = 20,
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
      acceptEdgeTolerance: acceptEdgeTolerance,
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
    double acceptEdgeTolerance = 20,
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
      acceptEdgeTolerance: acceptEdgeTolerance,
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
    this.acceptEdgeTolerance = 20,
  }) {
    _position = ValueNotifier<DraggingItemPosition>(
      handler.initialDraggingPosition,
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

    autoScroll?.start(
      viewport.size,
      _transformPointer(dragInfo.globalPosition),
    );
  }

  Offset _accumulatedDelta = Offset.zero;

  /// TODO: should remove placeholder when the pointer moves out of the original item boundary,
  /// instead of waiting until the drag ends?
  @override
  void update(DragUpdateDetails details) {
    final accumulated = _accumulatedDelta + details.delta;

    final accumulatedDelta = DraggingLayoutDelta(
      x: (accumulated.dx / dragSlotExtentX).round(),
      y: (accumulated.dy / dragSlotExtentY).round(),
      delta: accumulated,
    );

    /// for small dragging delta,
    /// we want to update the dragging item's position in real time
    /// without waiting for it to exceed the slot extent,
    final delta = DraggingLayoutDelta(
      x: (details.delta.dx / dragSlotExtentX).ceil(),
      y: (details.delta.dy / dragSlotExtentY).ceil(),
      delta: details.delta,
    );

    final updatedPosition = handler.updateDragging(accumulatedDelta, delta);

    if (updatedPosition != null) {
      _accumulatedDelta = accumulated;
      _position.value = updatedPosition;
    }

    autoScroll?.start(viewport.size, _transformPointer(details.globalPosition));
  }

  @override
  void end(DragEndDetails details) {
    final synthesized = handler.synthesize(
      details,
      _accumulatedDelta,
    );

    final accepted = isPointerInViewport(
      synthesized.globalPosition,
      tolerance: acceptEdgeTolerance,
    );

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

  bool isPointerInViewport(
    Offset globalPosition, {
    double tolerance = 0,
    double? velocity,
  }) {
    final pointerPosition = _transformPointer(globalPosition);

    final viewportRect = (Offset.zero & viewport.size).inflate(tolerance * 2);

    return viewportRect.contains(pointerPosition);
  }

  Offset _transformPointer(Offset globalPosition) =>
      viewport.globalToLocal(globalPosition);

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
  DraggingItemPosition? updateDragging(
    DraggingLayoutDelta accumulated,
    DraggingLayoutDelta delta,
  );

  void finishDragging(bool accepted);

  DragEndDetails synthesize(
    DragEndDetails details,
    Offset accumulated,
  ) => details;
}
