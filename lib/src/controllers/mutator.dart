import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

abstract mixin class DashboardItemMutator {
  List<LayoutItem> get items;
  void updateItems(List<LayoutItem> newItems);

  bool validLayoutRect(LayoutRect rect);

  List<LayoutItem>? _freezedItems;
  Offset _dragDelta = Offset.zero;

  double _dragSlotExtentX = 1.0;
  double _dragSlotExtentY = 1.0;

  DragInfo? _dragInfo;
  DashboardMutatorDelegate? _delegate;

  LayoutRect get _draggingItemRect => _dragInfo!.item.rect;

  bool get isMutating => _dragInfo != null;

  void startMutation(DragInfo dragInfo, DashboardMutatorDelegate delegate) {
    if (_dragInfo != null) return;

    _dragInfo = dragInfo;
    _freezedItems = List.unmodifiable(items);

    _dragDelta = Offset.zero;
    _delegate = delegate;

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

    print(
      "dx: $dx, dy: $dy, candidateRect: $candidateRect",
    ); // debug

    final repositionedItems = _delegate?.adopt(
      candidateRect,
      _dragInfo!,
      items,
    );

    if (repositionedItems != null) {
      assert(
        () {
          for (final item in repositionedItems) {
            if (item.id is PlaceholderId && item is! ItemPlaceholder) {
              return false;
            }
          }

          return true;
        }(),
        "All placeholders in the items list should be of type ItemPlaceholder.",
      );
      updateItems(repositionedItems);
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
    _delegate = null;
    _dragDelta = Offset.zero;
    _dragSlotExtentX = 1.0;
    _dragSlotExtentY = 1.0;
  }
}
