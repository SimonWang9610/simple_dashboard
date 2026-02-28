

## TODOs

- ~~keep dragging item alive when dragging out of the dashboard, and move it back when dragging back in. ensure the item does not lose its state when dragging out and back in.~~
- ~~auto scroll when dragging near the edge of the dashboard~~
- implement resize drag
- implement resize pointer check (determine fi the pointer may create a resize drag, and which edge it will resize)

### Issues

1. drag delta computation seems not very accurate along the scroll direction. For example, dragging an item pushes to the bottom edge does not continue auto-scroll, as the dy does not continue increasing

```dart
    _dragDelta += delta;

    final dx = (_dragDelta.dx / _dragSlotExtentX).round();
    final dy = (_dragDelta.dy / _dragSlotExtentY).round();

    final candidateRect = LayoutRect(
      x: _draggingItemRect.x + dx,
      y: _draggingItemRect.y + dy,
      size: _draggingItemRect.size,
    );

```