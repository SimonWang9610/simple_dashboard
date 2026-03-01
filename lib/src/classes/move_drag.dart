import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

final class MoveItemDrag extends ItemDrag {
  final DashboardMetricsManager metrics;
  final MoveDropStrategy strategy;
  final Offset initialPosition;

  /// Whether we should compute the final global position of the pointer
  /// and synthesize a new [DragEndDetails] when the drag is ended.
  ///
  /// For [MultiDragGestureRecognizer], when the drag is ended,
  /// it does not provider the final global position of the pointer,
  /// so we must compute it manually by accumulating the delta to the initial position.
  ///
  /// So when using [MoveItemDrag] with [MultiDragGestureRecognizer],
  /// you should set [synthesizedEnd] to true to get the correct final position in the [DragEndDetails].
  ///
  /// See also:
  ///   - [MultiDragPointerState]
  final bool synthesizedEnd;

  MoveItemDrag({
    required super.dragInfo,
    required super.mutator,
    required super.overlayState,
    required super.viewport,
    required this.strategy,
    required this.metrics,
    required this.initialPosition,
    required super.builder,
    super.onDragEnd,
    super.autoScroll,
    this.synthesizedEnd = true,
  });

  List<LayoutItem>? _freezedItems;

  @override
  void end(DragEndDetails details) {
    final synthesizedDetails = synthesizedEnd
        ? DragEndDetails(
            globalPosition: initialPosition + accumulatedDelta,
            velocity: details.velocity,
            primaryVelocity: details.primaryVelocity,
          )
        : details;

    super.end(synthesizedDetails);
  }

  @override
  void startDragging() {
    _freezedItems = List.unmodifiable(mutator.items);

    mutator.updateItems(
      mutator.items
          .map((i) => i.id == dragInfo.item.id ? i.placeholder : i)
          .toList(),
    );
  }

  @override
  void updateDragging(Offset delta) {
    final dx = (delta.dx / dragSlotExtentX).round();
    final dy = (delta.dy / dragSlotExtentY).round();

    final candidateRect = LayoutRect(
      x: dragInfo.item.rect.x + dx,
      y: dragInfo.item.rect.y + dy,
      size: dragInfo.item.rect.size,
    );

    if (!mutator.validateLayoutRect(candidateRect)) {
      return;
    }

    final itemsAfterMove = switch (strategy) {
      MoveDropStrategy.noCollision =>
        MoveDropDragHelper.handleNoCollisionStrategy(
          candidateRect,
          dragInfo,
          mutator.items,
        ),
      MoveDropStrategy.reflow => MoveDropDragHelper.handleReflowStrategy(
        metrics,
        candidateRect,
        dragInfo,
        mutator.items,
      ),
    };

    if (itemsAfterMove != null) {
      assert(
        () {
          for (final item in itemsAfterMove) {
            if (item.id is PlaceholderId && item is! ItemPlaceholder) {
              return false;
            }
          }

          return true;
        }(),
        "All placeholders in the items list should be of type ItemPlaceholder.",
      );
      mutator.updateItems(itemsAfterMove);
    }
  }

  @override
  void finishDragging(bool accepted) {
    if (accepted) {
      mutator.updateItems(
        mutator.items.map((i) {
          if (i is ItemPlaceholder && i.isPlaceholderOf(dragInfo.item.id)) {
            return i.item;
          }
          return i;
        }).toList(),
      );
    } else {
      mutator.updateItems(List.of(_freezedItems!));
    }

    _freezedItems = null;
  }
}

abstract class MoveDropDragHelper {
  static List<LayoutItem>? handleNoCollisionStrategy(
    LayoutRect rect,
    DragInfo dragInfo,
    List<LayoutItem> items,
  ) {
    final collisions = LayoutChecker.checkCollisions(
      items.where((i) => i.id is! PlaceholderId),
      rect,
    );

    if (collisions.hasCollision) {
      return null;
    }

    final placeholder = ItemPlaceholder(
      dragInfo.item.id,
      rect: rect,
    );

    return items.map((i) {
      if (i.id == placeholder.id) {
        return placeholder;
      }
      return i;
    }).toList();
  }

  static List<LayoutItem>? handleReflowStrategy(
    DashboardMetricsManager metrics,
    LayoutRect rect,
    DragInfo dragInfo,
    List<LayoutItem> items,
  ) {
    final noPlaceHolderItems = items.where((i) => i.id is! PlaceholderId);
    final collisions = LayoutChecker.checkCollisions(noPlaceHolderItems, rect);

    final placeholder = ItemPlaceholder(
      dragInfo.item.id,
      rect: rect,
    );

    if (!collisions.hasCollision) {
      return items.map((i) {
        if (i.id == placeholder.id) {
          return placeholder;
        }
        return i;
      }).toList();
    }

    final sorted = DashboardHelper.sort(noPlaceHolderItems, metrics.axis);

    final after = sorted.reversed
        .skipWhile((i) => i.id == dragInfo.item.id)
        .firstWhereOrNull((i) => i.rect.compare(rect, metrics.axis) < 0);

    final positioned = DashboardAfterPositioner(
      items: sorted,
      axis: metrics.axis,
      mainAxisSlots: metrics.mainAxisSlots,
      maxCrossSlots: metrics.maxCrossAxisSlots,
      afterId: after?.id,
      append: false,
    ).position(placeholder.id, placeholder.rect.size);

    final placeholderIndex = positioned.indexWhere(
      (i) => i.id == placeholder.id,
    );

    final newPlaceholder = placeholderIndex != -1
        ? positioned[placeholderIndex]
        : null;

    if (newPlaceholder == null) {
      return null;
    }

    positioned[placeholderIndex] = ItemPlaceholder(
      dragInfo.item.id,
      rect: newPlaceholder.rect,
    );

    return positioned;
  }
}
