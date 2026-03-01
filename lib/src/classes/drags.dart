import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/classes/move_drag.dart';
import 'package:simple_dashboard/src/classes/resize_drag.dart';

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
/// However, it delegates to the subclasses to handle the specific logic of
/// how the layout of items should be updated during dragging by implementation
///  of [startDragging], [updateDragging], and [finishDragging].
///
/// See also:
///   - [MoveItemDrag]: a drag for moving items.
///   - [ResizeItemDrag]: a drag for resizing items.
abstract base class ItemDrag extends Drag {
  final OverlayState overlayState;
  final DragInfo dragInfo;
  final AutoScroll? autoScroll;
  final RenderBox viewport;
  late final Offset distanceFromPointerToItemCenter;

  /// The accumulated delta since the start of dragging,
  /// which would be used to compute the relative shift of [LayoutItem]s during dragging.
  final ValueNotifier<Offset> _delta = ValueNotifier(Offset.zero);

  /// The overlay entry that displays the dragging feedback widget.
  late final OverlayEntry _entry;

  /// The feedback builder for the dragging item,
  /// which would be displayed in the overlay during dragging.
  final DraggingItemFeedbackBuilder builder;

  /// The mutator that would be used to update the layout of items during dragging.
  /// subclasses will use it to mutate the layout based on the dragging state
  /// in their implementation of [startDragging], [updateDragging], and [finishDragging].
  final DashboardItemMutator mutator;

  /// The extent of each slot in the main axis,
  /// which is used to compute how many slots the dragging item has shifted during dragging.
  late final double dragSlotExtentX;

  /// The extent of each slot in the cross axis,
  /// which is used to compute how many slots the dragging item has shifted during dragging.
  late final double dragSlotExtentY;

  /// The callback when the drag ends, which can be used to trigger additional actions after dragging.
  final VoidCallback? onDragEnd;

  factory ItemDrag.move({
    required DragInfo dragInfo,
    required DashboardItemMutator mutator,
    required OverlayState overlayState,
    required RenderBox viewport,
    required MoveDropStrategy strategy,
    required DashboardMetricsManager metrics,
    required Offset initialPosition,
    required DraggingItemFeedbackBuilder builder,
    bool synthesizedEnd,
    VoidCallback? onDragEnd,
    AutoScroll? autoScroll,
  }) = MoveItemDrag;

  factory ItemDrag.resize({
    required DragInfo dragInfo,
    required DashboardItemMutator mutator,
    required OverlayState overlayState,
    required RenderBox viewport,
    required ResizeDirection direction,
    required DraggingItemFeedbackBuilder builder,
    VoidCallback? onDragEnd,
    AutoScroll? autoScroll,
  }) = ResizeItemDrag;

  ItemDrag({
    required this.dragInfo,
    required this.overlayState,
    required this.viewport,
    required this.mutator,
    required this.builder,
    this.onDragEnd,
    this.autoScroll,
  }) {
    /// relative distance between the start pointer and the item position.
    distanceFromPointerToItemCenter = dragInfo.computeRelativeOffset();

    dragSlotExtentX = dragInfo.size.width > 0
        ? dragInfo.size.width / dragInfo.item.rect.size.width
        : 1.0;
    dragSlotExtentY = dragInfo.size.height > 0
        ? dragInfo.size.height / dragInfo.item.rect.size.height
        : 1.0;

    startDragging();

    _entry = OverlayEntry(
      builder: (context) => builder(context, dragInfo, _delta),
    );

    overlayState.insert(_entry);

    final result = _computePointerInViewport(dragInfo.origin);

    autoScroll?.start(result.$1, result.$2);
  }

  Offset get accumulatedDelta => _delta.value;

  /// TODO: should remove placeholder when the pointer moves out of the original item boundary,
  /// instead of waiting until the drag ends?
  @override
  void update(DragUpdateDetails details) {
    _delta.value += details.delta;

    updateDragging(_delta.value);

    final result = _computePointerInViewport(details.globalPosition);

    autoScroll?.start(result.$1, result.$2);
  }

  @override
  void end(DragEndDetails details) {
    final accepted = isPointerInViewport(details.globalPosition);

    finishDragging(accepted);
    _dispose();
    autoScroll?.stop();
    onDragEnd?.call();
  }

  @override
  void cancel() {
    finishDragging(false);
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

  /// TODO: consider velocity to determine whether the posinter is out of viewport
  bool isPointerInViewport(Offset globalPosition, {double? velocity}) {
    final pointerPosition = _computePointerInViewport(globalPosition).$2;
    final viewportRect = Offset.zero & viewport.size;

    return viewportRect.contains(pointerPosition);
  }

  void _dispose() {
    _delta.dispose();
    _entry.remove();
    _entry.dispose();
    autoScroll?.stop();
  }

  void startDragging();

  void updateDragging(Offset delta);

  void finishDragging(bool accepted);
}
