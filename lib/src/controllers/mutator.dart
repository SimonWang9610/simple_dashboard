import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

abstract mixin class DashboardItemMutator {
  List<LayoutItem> get items;
  void updateItems(List<LayoutItem> newItems);

  bool validLayoutRect(LayoutRect rect);

  List<LayoutItem>? _freezedItems;
  Offset _dragDelta = Offset.zero;

  double _dragSlotExtentX = 1.0;
  double _dragSlotExtentY = 1.0;

  DragInfo? _dragInfo;

  LayoutRect get _draggingItemRect => _dragInfo!.item.rect;

  bool get isMutating => _dragInfo != null;

  void startMutation(DragInfo dragInfo) {
    if (_dragInfo != null) return;

    _dragInfo = dragInfo;
    _freezedItems = List.unmodifiable(items);

    _dragDelta = Offset.zero;

    _dragSlotExtentX = dragInfo.size.width > 0
        ? dragInfo.size.width / dragInfo.item.rect.size.width
        : 1.0;
    _dragSlotExtentY = dragInfo.size.height > 0
        ? dragInfo.size.height / dragInfo.item.rect.size.height
        : 1.0;

    updateItems(
      _freezedItems!
          .map((i) => i.id == dragInfo.item.id ? i.placeholder : i)
          .toList(),
    );
  }

  void updateMutation(Offset delta) {
    if (_dragInfo == null) {
      _reset();
      return;
    }

    _dragDelta += delta;

    final dx = (_dragDelta.dx / _dragSlotExtentX).round();
    final dy = (_dragDelta.dy / _dragSlotExtentY).round();

    final candidateRect = LayoutRect(
      x: _draggingItemRect.x + dx,
      y: _draggingItemRect.y + dy,
      size: _draggingItemRect.size,
    );

    if (!validLayoutRect(candidateRect)) {
      return;
    }

    final result = LayoutChecker.checkCollisions(
      _freezedItems!.where((i) => i is! ItemPlaceholder),
      candidateRect,
    );

    if (!result.hasCollision) {
      final newPlaceholder = ItemPlaceholder(
        _dragInfo!.item.id,
        rect: candidateRect,
      );

      /// here we use the current items to update the old placeholder
      /// instead of using the freezed items that have no placeholder
      /// because we want the placeholder to be able to "jump" over other items when dragging
      updateItems(
        items.map(
          (i) {
            if (i.id == newPlaceholder.id) {
              return newPlaceholder;
            }
            return i;
          },
        ).toList(),
      );
    }
  }

  void endMutation(bool confirmed) {
    if (_dragInfo == null) return;

    if (confirmed) {
      updateItems(
        items.map((i) {
          if (i is ItemPlaceholder && i.isPlaceholderOf(_dragInfo!.item.id)) {
            return i.item;
          }
          return i;
        }).toList(),
      );
    } else {
      updateItems(List.of(_freezedItems!));
    }

    _reset();
  }

  void _reset() {
    _freezedItems = null;
    _dragInfo = null;
    _dragDelta = Offset.zero;
    _dragSlotExtentX = 1.0;
    _dragSlotExtentY = 1.0;
  }
}

final class EmptyMutatorDelegate {
  const EmptyMutatorDelegate();

  List<LayoutItem>? adopt(
    LayoutRect rect,
    DragInfo dragInfo,
    List<LayoutItem> items,
  ) {
    final collisions = LayoutChecker.checkCollisions(items, rect);

    if (collisions.hasCollision) {
      return null;
    }

    final newPlaceholder = ItemPlaceholder(
      dragInfo.item.id,
      rect: rect,
    );

    return items.map((i) {
      if (i.id == newPlaceholder.id) {
        return newPlaceholder;
      }
      return i;
    }).toList();
  }
}

final class ReorderMutatorDelegate {
  final DashboardAxis axis;
  const ReorderMutatorDelegate(this.axis);

  List<LayoutItem>? adopt(
    LayoutRect rect,
    DragInfo dragInfo,
    List<LayoutItem> items,
  ) {
    final collisions = LayoutChecker.checkCollisions(items, rect);

    if (!collisions.hasCollision) {
      final newPlaceholder = ItemPlaceholder(
        dragInfo.item.id,
        rect: rect,
      );

      return items.map((i) {
        if (i.id == newPlaceholder.id) {
          return newPlaceholder;
        }
        return i;
      }).toList();
    }
  }
}
