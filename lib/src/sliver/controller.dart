import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

abstract class DashboardController extends ChangeNotifier
    implements DashboardResizer, DashboardDragger {
  DashboardController._();

  DashboardAxis get axis;
  int get mainAxisSlots;
  int get maxCrossAxisSlots;
  List<LayoutItem> get items;
  List<LayoutItem> get sortedItems;

  set mainAxisSlots(int value);
  set axis(DashboardAxis value);
  set items(List<LayoutItem> value);

  void add(
    Object id,
    LayoutSize size, {
    required PositionStrategy strategy,
    Object? afterId,
  }) {
    assert(
      !items.any((item) => item.id == id),
      "Each item in the dashboard must have a unique id. An item with id [$id] already exists.",
    );

    final validSize = size.constrain(axis, mainAxisSlots);

    final positioner = switch (strategy) {
      PositionStrategy.aggressive => DashboardAggressivePositioner(
        items: items,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: maxCrossAxisSlots,
      ),
      PositionStrategy.append => DashboardAppendPositioner(
        items: items,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: maxCrossAxisSlots,
      ),
      PositionStrategy.after => DashboardAfterPositioner(
        items: items,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        afterId: afterId,
        maxCrossSlots: maxCrossAxisSlots,
      ),
      PositionStrategy.head => DashboardHeadPositioner(
        items: items,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: maxCrossAxisSlots,
      ),
    };

    final newItems = positioner.position(id, validSize);

    items = newItems;
  }

  void remove(Object id) {
    if (!items.any((item) => item.id == id)) {
      return;
    }

    final newItems = items.where((item) => item.id != id).toList();

    items = newItems;
  }

  factory DashboardController({
    DashboardAxis axis,
    required int mainAxisSlots,
    Iterable<LayoutItem>? initialItems,
  }) = _DashboardControllerImpl;
}

class _DashboardControllerImpl extends DashboardController
    with _DashboardControllerGestureImpl, _DashboardDraggerImpl {
  _DashboardControllerImpl({
    DashboardAxis axis = DashboardAxis.horizontal,
    required int mainAxisSlots,
    Iterable<LayoutItem>? initialItems,
  }) : _axis = axis,
       _mainAxisSlots = mainAxisSlots,
       super._() {
    /// ensure the initial items are valid and properly adopted
    final adopted = DashboardHelper.adoptMetrics(
      initialItems ?? [],
      axis,
      mainAxisSlots,
    );

    _refillItems(adopted);
  }

  DashboardAxis _axis;

  @override
  DashboardAxis get axis => _axis;

  @override
  set axis(DashboardAxis value) {
    _updateMetrics(value, null);
  }

  int _mainAxisSlots;

  @override
  int get mainAxisSlots => _mainAxisSlots;

  @override
  set mainAxisSlots(int value) {
    _updateMetrics(null, value);
  }

  int _maxCrossAxisSlots = 0;
  @override
  int get maxCrossAxisSlots => _maxCrossAxisSlots;

  late List<LayoutItem> _items;

  @override
  List<LayoutItem> get items => _items;

  List<LayoutItem>? _sortedItems;

  @override
  List<LayoutItem> get sortedItems {
    _sortedItems ??= DashboardHelper.sort(items, axis);
    return _sortedItems!;
  }

  @override
  set items(List<LayoutItem> value) {
    _refillItems(value);
    notifyListeners();
  }

  void _updateMetrics(DashboardAxis? newAxis, int? newMainAxisSlots) {
    if (newAxis == null && newMainAxisSlots == null) {
      return;
    }

    bool shouldReAdopt = false;

    if (newAxis != null && newAxis != axis) {
      _axis = newAxis;
      shouldReAdopt = true;
    }

    if (newMainAxisSlots != null && newMainAxisSlots != mainAxisSlots) {
      _mainAxisSlots = newMainAxisSlots;
      shouldReAdopt = true;
    }

    if (shouldReAdopt) {
      final adoptedItems = DashboardHelper.adoptMetrics(
        sortedItems,
        axis,
        mainAxisSlots,
      );
      _refillItems(adoptedItems);
      notifyListeners();
    }
  }

  /// Checks that the given items do not have any conflicts with each other.
  void _refillItems(Iterable<LayoutItem> items) {
    LayoutChecker.debugLayoutAssertions(items, axis, mainAxisSlots);

    _maxCrossAxisSlots = 0;

    for (final item in items) {
      final crossAxisSlots = switch (axis) {
        DashboardAxis.horizontal => item.rect.bottom,
        DashboardAxis.vertical => item.rect.right,
      };

      if (crossAxisSlots > _maxCrossAxisSlots) {
        _maxCrossAxisSlots = crossAxisSlots;
      }
    }

    _items = List.unmodifiable(items);
    _sortedItems = null;
  }
}

mixin _DashboardDraggerImpl on DashboardController, DashboardDragger {
  List<LayoutItem>? _freezedItems;
  Offset _dragDelta = Offset.zero;

  double _dragSlotExtentX = 1.0;
  double _dragSlotExtentY = 1.0;

  DragInfo? _dragInfo;

  LayoutRect get _draggingItemRect => _dragInfo!.item.rect;

  @override
  bool get isDragging => _dragInfo != null;

  @override
  void startDrag(DragInfo dragInfo) {
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

    items = _freezedItems!
        .map((i) => i.id == dragInfo.item.id ? i.placeholder : i)
        .toList();
  }

  @override
  void updateDrag(Offset delta) {
    if (_dragInfo == null) return;

    _dragDelta += delta;

    final dx = (_dragDelta.dx / _dragSlotExtentX).round();
    final dy = (_dragDelta.dy / _dragSlotExtentY).round();

    final candidateRect = LayoutRect(
      x: _draggingItemRect.x + dx,
      y: _draggingItemRect.y + dy,
      size: _draggingItemRect.size,
    );

    if (!LayoutChecker.isValidRect(
      candidateRect,
      axis,
      mainAxisSlots,
    )) {
      return;
    }

    final result = LayoutChecker.checkCollisions(
      _freezedItems!.where(
        (i) => i is! ItemPlaceholder && i.id != _dragInfo!.item.id,
      ),
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
      items = items.map(
        (i) {
          if (i.id == newPlaceholder.id) {
            return newPlaceholder;
          }
          return i;
        },
      ).toList();
    }
  }

  @override
  void endDrag(bool confirmed) {
    if (_dragInfo == null) return;

    if (confirmed) {
      items = items.map((i) {
        if (i is ItemPlaceholder && i.isPlaceholderOf(_dragInfo!.item.id)) {
          return i.item;
        }
        return i;
      }).toList();
    } else {
      items = List.of(_freezedItems!);
    }

    _freezedItems = null;
    _dragInfo = null;
    _dragDelta = Offset.zero;
    _dragSlotExtentX = 1.0;
    _dragSlotExtentY = 1.0;
  }
}

// =============================================================================
// Combined resize + drag gesture mixin
// =============================================================================

mixin _DashboardControllerGestureImpl on DashboardController, DashboardResizer {
  // ---------------------------------------------------------------------------
  // Shared painter / notifier
  // ---------------------------------------------------------------------------

  @override
  DashboardPlaceholderPainter? get placeholderPainter => _painter;

  final _placeholderNotifier = ValueNotifier<ItemPlaceholder?>(null);
  DashboardPlaceholderPainter? _painter;

  // ---------------------------------------------------------------------------
  // Resize state
  // ---------------------------------------------------------------------------

  LayoutItem? _resizingItem;
  ResizeDirection? _resizeDirection;
  Offset _resizeAccumDelta = Offset.zero;
  double _resizeSlotExtentX = 1.0;
  double _resizeSlotExtentY = 1.0;

  // ---------------------------------------------------------------------------
  // Drag state
  // ---------------------------------------------------------------------------

  // LayoutItem? _draggingItem;
  // Offset _dragAccumDelta = Offset.zero;
  // double _dragSlotExtentX = 1.0;
  // double _dragSlotExtentY = 1.0;

  // DragStrategy _dragStrategy = DragStrategy.swap;

  // DragResult? _lastDragResult;

  // @override
  // DragStrategy get dragStrategy => _dragStrategy;

  // DashboardDragDelegate? _dragDelegate;

  // @override
  // set dragStrategy(DragStrategy value) {
  //   _dragStrategy = value;
  // }

  // ---------------------------------------------------------------------------
  // DashboardResizer
  // ---------------------------------------------------------------------------

  @override
  void startResize(
    ResizeDirection direction,
    LayoutItem item,
    Size widgetSize,
  ) {
    _resizingItem = item;
    _resizeDirection = direction;
    _resizeAccumDelta = Offset.zero;

    // Approximate slot extents from widget pixel size ÷ item slot dimensions.
    // Small spacing values (4 px default) cause a negligible error.
    _resizeSlotExtentX = widgetSize.width > 0
        ? widgetSize.width / item.rect.size.width
        : 1.0;
    _resizeSlotExtentY = widgetSize.height > 0
        ? widgetSize.height / item.rect.size.height
        : 1.0;

    _setPlaceholder(item.placeholder);
    notifyListeners();
  }

  @override
  void updateResize(Offset localPosition, Offset delta) {
    if (_resizingItem == null || _resizeDirection == null) return;

    _resizeAccumDelta += delta;

    final dx = (_resizeAccumDelta.dx / _resizeSlotExtentX).round();
    final dy = (_resizeAccumDelta.dy / _resizeSlotExtentY).round();

    final newRect = _computeResizeRect(_resizingItem!.rect, dx, dy);

    if (newRect != _placeholderNotifier.value?.rect) {
      _setPlaceholder(
        LayoutItem(id: _resizingItem!.id, rect: newRect).placeholder,
      );
    }
  }

  @override
  void endResize(bool confirmed) {
    if (_resizingItem != null) {
      if (confirmed && _placeholderNotifier.value != null) {
        final finalRect = _placeholderNotifier.value!.rect;
        _applyResizeResult(_resizingItem!, finalRect);
      }
      _resizingItem = null;
      _resizeDirection = null;
      _resizeAccumDelta = Offset.zero;
    }

    _clearPainter();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // DashboardDragger
  // ---------------------------------------------------------------------------

  // @override
  // void startDrag(LayoutItem item, Size widgetSize) {
  //   _dragDelegate = switch (dragStrategy) {
  //     DragStrategy.emptySpace => const EmptySpaceDragDelegate(),
  //     DragStrategy.swap => const SwapDragDelegate(),
  //   };

  //   _draggingItem = item;
  //   _dragAccumDelta = Offset.zero;
  //   _lastDragResult = null;

  //   _dragSlotExtentX = widgetSize.width > 0
  //       ? widgetSize.width / item.rect.size.width
  //       : 1.0;
  //   _dragSlotExtentY = widgetSize.height > 0
  //       ? widgetSize.height / item.rect.size.height
  //       : 1.0;

  //   _setPlaceholder(item.placeholder);
  //   notifyListeners();
  // }

  // @override
  // void updateDrag(Offset delta) {
  //   if (_draggingItem == null) return;

  //   _dragAccumDelta += delta;

  //   final dx = (_dragAccumDelta.dx / _dragSlotExtentX).round();
  //   final dy = (_dragAccumDelta.dy / _dragSlotExtentY).round();

  //   final original = _draggingItem!.rect;
  //   final targetRect = LayoutRect(
  //     x: original.x + dx,
  //     y: original.y + dy,
  //     size: original.size,
  //   );

  //   final result = _dragDelegate!.findCandidatePosition(
  //     draggingItem: _draggingItem!,
  //     targetRect: targetRect,
  //     currentItems: items,
  //     axis: axis,
  //     mainAxisSlots: mainAxisSlots,
  //   );

  //   _lastDragResult = result;

  //   final placeholder = result != null
  //       ? LayoutItem(
  //           id: _draggingItem!.id,
  //           rect: result.candidateRect,
  //         ).placeholder
  //       : null;

  //   if (_placeholderNotifier.value?.rect != placeholder?.rect) {
  //     _setPlaceholder(placeholder);
  //   }
  // }

  // @override
  // void endDrag(bool confirmed) {
  //   if (_draggingItem != null) {
  //     if (confirmed && _lastDragResult != null) {
  //       final updatedItems = _dragDelegate!.applyDrag(
  //         draggingItem: _draggingItem!,
  //         result: _lastDragResult!,
  //         currentItems: items,
  //         axis: axis,
  //         mainAxisSlots: mainAxisSlots,
  //       );
  //       items = updatedItems; // calls notifyListeners via setter
  //     }
  //     _draggingItem = null;
  //     _dragAccumDelta = Offset.zero;
  //     _lastDragResult = null;
  //   }

  //   _dragDelegate = null;

  //   _clearPainter();
  //   notifyListeners();
  // }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _painter = null;
    _placeholderNotifier.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Resize helpers
  // ---------------------------------------------------------------------------

  LayoutRect _computeResizeRect(LayoutRect original, int dx, int dy) {
    switch (_resizeDirection!) {
      case ResizeDirection.right:
        return _applyHorizontalResize(original, dx);
      case ResizeDirection.left:
        return _applyLeftResize(original, dx);
      case ResizeDirection.down:
        return _applyVerticalResize(original, dy);
      case ResizeDirection.up:
        return _applyUpResize(original, dy);
      case ResizeDirection.bottomRight:
        final h = _applyHorizontalResize(original, dx);
        return _applyVerticalResize(h, dy);
      case ResizeDirection.bottomLeft:
        final h = _applyLeftResize(original, dx);
        return _applyVerticalResize(h, dy);
      case ResizeDirection.topRight:
        final h = _applyHorizontalResize(original, dx);
        return _applyUpResize(h, dy);
      case ResizeDirection.topLeft:
        final h = _applyLeftResize(original, dx);
        return _applyUpResize(h, dy);
    }
  }

  /// Resize by moving the **right** edge (dx > 0 = expand, dx < 0 = shrink).
  LayoutRect _applyHorizontalResize(LayoutRect original, int dx) {
    final item = _resizingItem!;
    final minW = item.minSize?.width ?? 1;
    final maxW = item.maxSize?.width ?? _mainAxisLimit(original);
    final clampedMax = maxW.clamp(minW, _mainAxisLimit(original));

    int newW = (original.size.width + dx).clamp(minW, clampedMax);

    if (dx > 0) {
      // Expanding right – check if neighbouring items allow it.
      newW = _maxRightWidth(original, newW).clamp(minW, newW);
    }

    return LayoutRect(
      x: original.x,
      y: original.y,
      size: LayoutSize(width: newW, height: original.size.height),
    );
  }

  /// Resize by moving the **left** edge (dx < 0 = expand left, dx > 0 = shrink).
  LayoutRect _applyLeftResize(LayoutRect original, int dx) {
    final item = _resizingItem!;
    final minW = item.minSize?.width ?? 1;
    final maxW = item.maxSize?.width;

    // New left = original.x + dx, clamped so width ≥ minW and x ≥ 0.
    int newLeft = (original.x + dx).clamp(0, original.right - minW);

    if (maxW != null) {
      // Don't let width exceed maxW.
      final minLeft = original.right - maxW;
      newLeft = newLeft.clamp(minLeft, original.right - minW);
    }

    if (dx < 0) {
      // Expanding left – check neighbouring items.
      newLeft = _minLeftEdge(original, newLeft).clamp(newLeft, original.x);
    }

    final newW = original.right - newLeft;
    return LayoutRect(
      x: newLeft,
      y: original.y,
      size: LayoutSize(width: newW, height: original.size.height),
    );
  }

  /// Resize by moving the **bottom** edge (dy > 0 = expand, dy < 0 = shrink).
  LayoutRect _applyVerticalResize(LayoutRect original, int dy) {
    final item = _resizingItem!;
    final minH = item.minSize?.height ?? 1;
    final maxH = item.maxSize?.height ?? _crossAxisLimit(original);
    final clampedMax = maxH.clamp(minH, _crossAxisLimit(original));

    int newH = (original.size.height + dy).clamp(minH, clampedMax);

    if (dy > 0) {
      newH = _maxDownHeight(original, newH).clamp(minH, newH);
    }

    return LayoutRect(
      x: original.x,
      y: original.y,
      size: LayoutSize(width: original.size.width, height: newH),
    );
  }

  /// Resize by moving the **top** edge (dy < 0 = expand up, dy > 0 = shrink).
  LayoutRect _applyUpResize(LayoutRect original, int dy) {
    final item = _resizingItem!;
    final minH = item.minSize?.height ?? 1;
    final maxH = item.maxSize?.height;

    int newTop = (original.y + dy).clamp(0, original.bottom - minH);

    if (maxH != null) {
      final minTop = original.bottom - maxH;
      newTop = newTop.clamp(minTop, original.bottom - minH);
    }

    if (dy < 0) {
      newTop = _minTopEdge(original, newTop).clamp(newTop, original.y);
    }

    final newH = original.bottom - newTop;
    return LayoutRect(
      x: original.x,
      y: newTop,
      size: LayoutSize(width: original.size.width, height: newH),
    );
  }

  // ---------------------------------------------------------------------------
  // Collision constraints for resize
  // ---------------------------------------------------------------------------

  /// Maximum allowed right edge when expanding right.
  ///
  /// Returns the largest width (≥ current width) such that no neighbour would
  /// be squished below its minimum width.
  int _maxRightWidth(LayoutRect original, int desiredWidth) {
    final desiredRight = original.x + desiredWidth;
    int maxRight = desiredRight;

    for (final other in items) {
      if (other.id == _resizingItem!.id) continue;
      // Y-axis overlap?
      if (other.rect.top >= original.bottom ||
          other.rect.bottom <= original.top) {
        continue;
      }
      // Is this item in the expansion zone?
      if (other.rect.left >= original.right && other.rect.left < desiredRight) {
        final minW = other.minSize?.width ?? 1;
        // The item would be squished to width = other.right - desiredRight.
        // Require: other.right - new_right ≥ minW  →  new_right ≤ other.right - minW.
        final cap = other.rect.right - minW;
        if (cap < maxRight) maxRight = cap;
      }
    }

    return maxRight - original.x; // convert back to width
  }

  /// Minimum allowed left edge when expanding left.
  int _minLeftEdge(LayoutRect original, int desiredLeft) {
    int minLeft = desiredLeft;

    for (final other in items) {
      if (other.id == _resizingItem!.id) continue;
      if (other.rect.top >= original.bottom ||
          other.rect.bottom <= original.top) {
        continue;
      }
      // Item is to the left and in the expansion zone.
      if (other.rect.right <= original.left && other.rect.right > desiredLeft) {
        final minW = other.minSize?.width ?? 1;
        // Squished width = desiredLeft - other.left ≥ minW  →  desiredLeft ≥ other.left + minW.
        final floor = other.rect.left + minW;
        if (floor > minLeft) minLeft = floor;
      }
    }

    return minLeft;
  }

  /// Maximum allowed height when expanding downward.
  int _maxDownHeight(LayoutRect original, int desiredHeight) {
    final desiredBottom = original.y + desiredHeight;
    int maxBottom = desiredBottom;

    for (final other in items) {
      if (other.id == _resizingItem!.id) continue;
      if (other.rect.left >= original.right ||
          other.rect.right <= original.left) {
        continue;
      }
      if (other.rect.top >= original.bottom && other.rect.top < desiredBottom) {
        final minH = other.minSize?.height ?? 1;
        final cap = other.rect.bottom - minH;
        if (cap < maxBottom) maxBottom = cap;
      }
    }

    return maxBottom - original.y;
  }

  /// Minimum allowed top edge when expanding upward.
  int _minTopEdge(LayoutRect original, int desiredTop) {
    int minTop = desiredTop;

    for (final other in items) {
      if (other.id == _resizingItem!.id) continue;
      if (other.rect.left >= original.right ||
          other.rect.right <= original.left) {
        continue;
      }
      if (other.rect.bottom <= original.top && other.rect.bottom > desiredTop) {
        final minH = other.minSize?.height ?? 1;
        final floor = other.rect.top + minH;
        if (floor > minTop) minTop = floor;
      }
    }

    return minTop;
  }

  // ---------------------------------------------------------------------------
  // Apply confirmed resize (squish neighbouring items)
  // ---------------------------------------------------------------------------

  void _applyResizeResult(LayoutItem resizingItem, LayoutRect finalRect) {
    final original = resizingItem.rect;

    final newItems = items.map((item) {
      if (item.id == resizingItem.id) {
        return LayoutItem(
          id: item.id,
          rect: finalRect,
          minSize: item.minSize,
          maxSize: item.maxSize,
        );
      }

      // Squish items that conflict with the new rect.
      final squished = _squishItem(item, original, finalRect);
      return squished ?? item;
    }).toList();

    items = newItems; // triggers notifyListeners
  }

  /// Returns a resized [item] if it needs to be squished to make room for the
  /// resizing item that moved from [original] to [finalRect].  Returns null if
  /// no squishing is needed.
  LayoutItem? _squishItem(
    LayoutItem item,
    LayoutRect original,
    LayoutRect finalRect,
  ) {
    if (!item.rect.hasConflicts(finalRect)) return null;
    // Item did not conflict with the original rect, so it's newly covered.
    if (item.rect.hasConflicts(original)) return null;

    final minW = item.minSize?.width ?? 1;
    final minH = item.minSize?.height ?? 1;

    int nx = item.rect.x;
    int ny = item.rect.y;
    int nw = item.rect.size.width;
    int nh = item.rect.size.height;

    // Right expansion: squish item's left edge.
    if (finalRect.right > original.right &&
        item.rect.left < finalRect.right &&
        item.rect.left >= original.right) {
      nx = finalRect.right;
      nw = item.rect.right - finalRect.right;
      if (nw < minW)
        return null; // safety – shouldn't happen if constraints held
    }

    // Left expansion: squish item's right edge.
    if (finalRect.left < original.left &&
        item.rect.right > finalRect.left &&
        item.rect.right <= original.left) {
      nw = finalRect.left - item.rect.left;
      if (nw < minW) return null;
    }

    // Down expansion: squish item's top edge.
    if (finalRect.bottom > original.bottom &&
        item.rect.top < finalRect.bottom &&
        item.rect.top >= original.bottom) {
      ny = finalRect.bottom;
      nh = item.rect.bottom - finalRect.bottom;
      if (nh < minH) return null;
    }

    // Up expansion: squish item's bottom edge.
    if (finalRect.top < original.top &&
        item.rect.bottom > finalRect.top &&
        item.rect.bottom <= original.top) {
      nh = finalRect.top - item.rect.top;
      if (nh < minH) return null;
    }

    return LayoutItem(
      id: item.id,
      rect: LayoutRect(
        x: nx,
        y: ny,
        size: LayoutSize(width: nw, height: nh),
      ),
      minSize: item.minSize,
      maxSize: item.maxSize,
    );
  }

  // ---------------------------------------------------------------------------
  // Axis limit helpers
  // ---------------------------------------------------------------------------

  int _mainAxisLimit(LayoutRect original) {
    return switch (axis) {
      DashboardAxis.horizontal => mainAxisSlots - original.x,
      DashboardAxis.vertical => 1 << 20, // cross axis is unbounded
    };
  }

  int _crossAxisLimit(LayoutRect original) {
    return switch (axis) {
      DashboardAxis.horizontal => 1 << 20, // cross axis is unbounded
      DashboardAxis.vertical => mainAxisSlots - original.y,
    };
  }

  // ---------------------------------------------------------------------------
  // Painter helpers
  // ---------------------------------------------------------------------------

  void _setPlaceholder(ItemPlaceholder? placeholder) {
    _placeholderNotifier.value = placeholder;
    if (placeholder != null) {
      _painter ??= DashboardPlaceholderPainter(_placeholderNotifier);
    }
  }

  void _clearPainter() {
    _placeholderNotifier.value = null;
    _painter = null;
  }
}
