import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

final class MoveDragHandler extends DragLayoutHandler {
  final DashboardMetricsManager metrics;
  final MoveDropStrategy strategy;
  final Offset initialPosition;
  final bool synthesizedEnd;

  MoveDragHandler({
    required this.strategy,
    required this.metrics,
    required this.initialPosition,
    required super.draggingItem,
    required super.mutator,
    required super.initialDraggingPosition,
    this.synthesizedEnd = true,
  });

  List<LayoutItem>? _freezedItems;

  @override
  DragEndDetails synthesize(
    DragEndDetails details,
    Offset accumulated,
  ) {
    if (!synthesizedEnd) {
      return details;
    }

    return DragEndDetails(
      globalPosition: initialPosition + accumulated,
      velocity: details.velocity,
      primaryVelocity: details.primaryVelocity,
    );
  }

  @override
  void startDragging() {
    _freezedItems = List.unmodifiable(mutator.items);

    mutator.updateItems(
      mutator.items
          .map((i) => i.id == draggingItem.id ? i.placeholder : i)
          .toList(),
    );
  }

  @override
  DraggingItemPosition? updateDragging(
    DraggingLayoutDelta accumulated,
    DraggingLayoutDelta delta,
  ) {
    final candidateRect = LayoutRect(
      x: draggingItem.rect.x + accumulated.x,
      y: draggingItem.rect.y + accumulated.y,
      size: draggingItem.rect.size,
    );

    if (!mutator.validateLayoutRect(candidateRect)) {
      return initialDraggingPosition.move(accumulated.delta);
    }

    final itemsAfterMove = switch (strategy) {
      MoveDropStrategy.noCollision => _Helper.handleNoCollisionStrategy(
        candidateRect,
        draggingItem,
        mutator.items,
      ),
      MoveDropStrategy.reflow => _Helper.handleReflowStrategy(
        metrics,
        candidateRect,
        draggingItem,
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

    return initialDraggingPosition.move(accumulated.delta);
  }

  @override
  void finishDragging(bool accepted) {
    if (accepted) {
      mutator.updateItems(
        mutator.items.map((i) {
          if (i is ItemPlaceholder && i.isPlaceholderOf(draggingItem.id)) {
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

abstract class _Helper {
  static List<LayoutItem>? handleNoCollisionStrategy(
    LayoutRect rect,
    LayoutItem draggingItem,
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
      draggingItem.id,
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
    LayoutItem draggingItem,
    List<LayoutItem> items,
  ) {
    final noPlaceHolderItems = items.where((i) => i.id is! PlaceholderId);
    final collisions = LayoutChecker.checkCollisions(noPlaceHolderItems, rect);

    final placeholder = ItemPlaceholder(
      draggingItem.id,
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
        .skipWhile((i) => i.id == draggingItem.id)
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
      draggingItem.id,
      rect: newPlaceholder.rect,
    );

    return positioned;
  }
}
