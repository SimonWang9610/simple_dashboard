import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

// TODO: implement resize drag update logic
final class ResizeItemDrag extends ItemDrag {
  final ResizeDirection direction;
  ResizeItemDrag({
    required super.dragInfo,
    required super.mutator,
    required super.overlayState,
    required super.viewport,
    required this.direction,
    required super.builder,
    super.onDragEnd,
    super.autoScroll,
  });

  List<LayoutItem>? _freezedItems;

  @override
  void startDragging() {
    _freezedItems = List.unmodifiable(mutator.items);

    mutator.updateItems(
      _freezedItems!
          .map((i) => i.id == dragInfo.item.id ? i.placeholder : i)
          .toList(),
    );
  }

  @override
  void updateDragging(Offset delta) {
    final dx = (delta.dx / dragSlotExtentX).round();
    final dy = (delta.dy / dragSlotExtentY).round();

    final candidateRect = LayoutRect(
      x: dragInfo.item.rect.x,
      y: dragInfo.item.rect.y,
      size: LayoutSize(
        width: dragInfo.item.rect.size.width + dx,
        height: dragInfo.item.rect.size.height + dy,
      ),
    );

    if (!mutator.validateLayoutRect(candidateRect)) {
      return;
    }

    throw UnimplementedError("Resize dragging is not implemented yet");
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
