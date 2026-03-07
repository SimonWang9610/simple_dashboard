import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

final class ResizeDragHandler extends DragLayoutHandler {
  final ResizeDirection direction;

  ResizeDragHandler({
    required this.direction,
    required super.draggingItem,
    required super.mutator,
    required super.initialDraggingPosition,
  });

  List<LayoutItem>? _freezedItems;

  @override
  void startDragging() {
    _freezedItems = List.unmodifiable(mutator.items);

    _currentPlaceholder = draggingItem.placeholder;

    mutator.updateItems(
      _freezedItems!
          .map((i) => i.id == draggingItem.id ? _currentPlaceholder! : i)
          .toList(),
    );
  }

  ItemPlaceholder? _currentPlaceholder;

  @override
  DraggingItemPosition? updateDragging(
    DraggingLayoutDelta accumulated,
    DraggingLayoutDelta _,
  ) {
    // print("$direction, accumulated: $accumulated, delta: $delta");
    final candidateRect = ResizeDragHelper.computeCandidateRect(
      accumulated.x,
      accumulated.y,
      draggingItem.rect,
      direction,
    );

    if (!mutator.validateLayoutRect(candidateRect) ||
        !draggingItem.canAcceptSize(candidateRect.size)) {
      return null;
    }

    /// all onstage items have been resized relative to the previous placeholder,
    /// so the incoming dx and dy should be relative to the previous placeholder's position
    /// instead of the original dragging item's position,
    // final shiftedX = candidateRect.x - _currentPlaceholder!.rect.x;
    // final shiftedY = candidateRect.y - _currentPlaceholder!.rect.y;

    final resolved = ResizeDragHelper.resolveCollision(
      draggingItem,
      candidateRect,
      direction,
      mutator.items,
      mutator.validateLayoutRect,
    );

    if (resolved != null) {
      _currentPlaceholder = resolved.$1;
      mutator.updateItems(resolved.$2);
    }

    return resolved != null
        ? initialDraggingPosition.resize(direction, accumulated.delta)
        : null;
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

abstract class ResizeDragHelper {
  static LayoutRect computeCandidateRect(
    int dx,
    int dy,
    LayoutRect rect,
    ResizeDirection direction,
  ) {
    int x = rect.x;
    int y = rect.y;
    int width = rect.size.width;
    int height = rect.size.height;

    if (direction.isRightEdge) {
      width = width + dx;
    } else if (direction.isLeftEdge) {
      x = x + dx;
      width = width - dx;
    }

    if (direction.isBottomEdge) {
      height = height + dy;
    } else if (direction.isTopEdge) {
      y = y + dy;
      height = height - dy;
    }

    final candidate = LayoutRect(
      x: x,
      y: y,
      size: LayoutSize(
        width: width,
        height: height,
      ),
    );

    return candidate;
  }

  static (ItemPlaceholder, List<LayoutItem>)? resolveCollision(
    LayoutItem draggingItem,
    LayoutRect candidateRect,
    ResizeDirection direction,
    List<LayoutItem> items,
    bool Function(LayoutRect) validateLayoutRect,
  ) {
    final noPlaceHolderItems = items.where((i) => i.id is! PlaceholderId);

    final collisions = LayoutChecker.checkCollisions(
      noPlaceHolderItems,
      candidateRect,
    );

    if (!collisions.hasCollision) {
      final placeholder = ItemPlaceholder(
        draggingItem.id,
        rect: candidateRect,
      );

      return (
        placeholder,
        items.map((i) {
          if (i.id == placeholder.id) {
            return placeholder;
          }
          return i;
        }).toList(),
      );
    }

    /// 1. iterate through the collisions and apply the same delta according to the collision direction and resize direction.
    /// For each collided item, determine which axis/axes it is affected by based on whether it extends
    /// beyond the original dragging item's edges. Then reverse only the relevant delta components and
    /// use the corresponding single-axis (or diagonal) opposite direction with [computeCandidateRect].
    final allCollisions = collisions.collisions;

    final newRects = <Object, LayoutRect>{};

    for (final item in allCollisions) {
      final itemCandidate = _resizeCollidedItem(
        candidateRect,
        direction,
        item.rect,
      );

      if (itemCandidate == null) {
        continue;
      }

      /// the item candidate cannot be resized to the new rect, or the new rect is invalid,
      /// then the resolve fails and returns null, which should eventually discard this resize operation.
      if (!item.canAcceptSize(itemCandidate.size) ||
          !validateLayoutRect(itemCandidate)) {
        return null;
      }

      newRects[item.id] = itemCandidate;
    }

    final placeholder = ItemPlaceholder(
      draggingItem.id,
      rect: candidateRect,
    );

    final updatedItems = items.map((i) {
      if (i.id == placeholder.id) {
        return placeholder;
      }

      final newRect = newRects[i.id];

      if (newRect != null) {
        return LayoutItem(
          id: i.id,
          rect: newRect,
          minSize: i.minSize,
          maxSize: i.maxSize,
        );
      }

      return i;
    }).toList();

    if (LayoutChecker.findFirstConflictItems(updatedItems) != null) {
      return null;
    }

    return (
      placeholder,
      updatedItems,
    );
  }

  static LayoutRect? _resizeCollidedItem(
    LayoutRect candidate,
    ResizeDirection resizeDirection,
    LayoutRect itemRect,
  ) {
    final isYAffected =
        (resizeDirection.isBottomEdge && candidate.bottom > itemRect.top) ||
        (resizeDirection.isTopEdge && candidate.top < itemRect.bottom);

    final isXAffected =
        (resizeDirection.isRightEdge && candidate.right > itemRect.left) ||
        (resizeDirection.isLeftEdge && candidate.left < itemRect.right);

    if (!isXAffected && !isYAffected) {
      return null;
    }

    final overlapWidth =
        (candidate.right < itemRect.right ? candidate.right : itemRect.right) -
        (candidate.left > itemRect.left ? candidate.left : itemRect.left);
    final overlapHeight =
        (candidate.bottom < itemRect.bottom
            ? candidate.bottom
            : itemRect.bottom) -
        (candidate.top > itemRect.top ? candidate.top : itemRect.top);

    final resolvedDx = switch (resizeDirection) {
      ResizeDirection.right ||
      ResizeDirection.topRight ||
      ResizeDirection.bottomRight => overlapWidth,
      ResizeDirection.left ||
      ResizeDirection.topLeft ||
      ResizeDirection.bottomLeft => -overlapWidth,
      _ => 0,
    };

    final resolvedDy = switch (resizeDirection) {
      ResizeDirection.down ||
      ResizeDirection.bottomLeft ||
      ResizeDirection.bottomRight => overlapHeight,
      ResizeDirection.up ||
      ResizeDirection.topLeft ||
      ResizeDirection.topRight => -overlapHeight,
      _ => 0,
    };

    final itemCandidate = computeCandidateRect(
      isXAffected ? resolvedDx : 0,
      isYAffected ? resolvedDy : 0,
      itemRect,
      resizeDirection.opposite,
    );

    return itemCandidate;
  }
}
