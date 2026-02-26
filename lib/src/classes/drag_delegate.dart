import 'package:simple_dashboard/simple_dashboard.dart';

/// The result produced by a [DashboardDragDelegate] when a valid drop position
/// is found.
class DragResult {
  /// Where the dragging item should be placed.
  final LayoutRect candidateRect;

  /// The item that was displaced by the drag (swap strategy only).
  final LayoutItem? displacedItem;

  /// The rect the displaced item moves to (swap strategy only).
  final LayoutRect? displacedRect;

  const DragResult({
    required this.candidateRect,
    this.displacedItem,
    this.displacedRect,
  });
}

/// Abstract base for the two drag-and-drop placement strategies.
///
/// Create a concrete subclass (or use [EmptySpaceDragDelegate] /
/// [SwapDragDelegate]) and assign it to the dashboard controller before
/// dragging starts.
abstract class DashboardDragDelegate {
  const DashboardDragDelegate();

  /// Try to find a valid position for [draggingItem] given the approximate
  /// [targetRect] computed from the accumulated pixel delta.
  ///
  /// Returns a [DragResult] when a valid candidate exists, or `null` when no
  /// valid drop position is available (placeholder should be hidden).
  DragResult? findCandidatePosition({
    required LayoutItem draggingItem,
    required LayoutRect targetRect,
    required List<LayoutItem> currentItems,
    required DashboardAxis axis,
    required int mainAxisSlots,
  });

  /// Apply the confirmed drag to [currentItems] and return the updated list.
  List<LayoutItem> applyDrag({
    required LayoutItem draggingItem,
    required DragResult result,
    required List<LayoutItem> currentItems,
    required DashboardAxis axis,
    required int mainAxisSlots,
  });

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  /// Clamp [rect] so it stays within valid grid bounds.
  LayoutRect clampRect(LayoutRect rect, DashboardAxis axis, int mainAxisSlots) {
    switch (axis) {
      case DashboardAxis.horizontal:
        // x is bounded by mainAxisSlots; y is the (unbounded) cross axis.
        final cx = rect.x.clamp(0, mainAxisSlots - rect.size.width);
        final cy = rect.y.clamp(0, 1 << 30);
        if (cx == rect.x && cy == rect.y) return rect;
        return LayoutRect(x: cx, y: cy, size: rect.size);
      case DashboardAxis.vertical:
        // y is bounded by mainAxisSlots; x is the (unbounded) cross axis.
        final cy = rect.y.clamp(0, mainAxisSlots - rect.size.height);
        final cx = rect.x.clamp(0, 1 << 30);
        if (cx == rect.x && cy == rect.y) return rect;
        return LayoutRect(x: cx, y: cy, size: rect.size);
    }
  }

  bool _hasConflicts(LayoutRect rect, Iterable<LayoutItem> items) {
    for (final item in items) {
      if (item.rect.hasConflicts(rect)) return true;
    }
    return false;
  }
}

// =============================================================================
// Strategy 1: Empty-space
// =============================================================================

/// Drag-and-drop strategy that only allows a drop when the target grid area is
/// completely empty (no other items overlap the candidate position).
class EmptySpaceDragDelegate extends DashboardDragDelegate {
  const EmptySpaceDragDelegate();

  @override
  DragResult? findCandidatePosition({
    required LayoutItem draggingItem,
    required LayoutRect targetRect,
    required List<LayoutItem> currentItems,
    required DashboardAxis axis,
    required int mainAxisSlots,
  }) {
    final clamped = clampRect(targetRect, axis, mainAxisSlots);
    final others = currentItems.where((i) => i.id != draggingItem.id);
    if (!_hasConflicts(clamped, others)) {
      return DragResult(candidateRect: clamped);
    }
    return null;
  }

  @override
  List<LayoutItem> applyDrag({
    required LayoutItem draggingItem,
    required DragResult result,
    required List<LayoutItem> currentItems,
    required DashboardAxis axis,
    required int mainAxisSlots,
  }) {
    return currentItems.map((item) {
      if (item.id != draggingItem.id) return item;
      return LayoutItem(
        id: item.id,
        rect: result.candidateRect,
        minSize: item.minSize,
        maxSize: item.maxSize,
      );
    }).toList();
  }
}

// =============================================================================
// Strategy 2: Swap
// =============================================================================

/// Drag-and-drop strategy that allows a drop by temporarily swapping the
/// dragging item with the most-overlapped item beneath it, provided the
/// displaced item can fit somewhere else.
///
/// * If the target area is empty, it behaves identically to
///   [EmptySpaceDragDelegate].
/// * If items overlap the target area, the one with the largest overlap is
///   chosen as the *displaced* item.
/// * The displaced item is tentatively moved:
///   - If the two items have the **same size**, they are swapped directly.
///   - Otherwise, aggressive positioning is used to find a valid slot for
///     the displaced item (excluding both items from the search space).
class SwapDragDelegate extends DashboardDragDelegate {
  const SwapDragDelegate();

  @override
  DragResult? findCandidatePosition({
    required LayoutItem draggingItem,
    required LayoutRect targetRect,
    required List<LayoutItem> currentItems,
    required DashboardAxis axis,
    required int mainAxisSlots,
  }) {
    final clamped = clampRect(targetRect, axis, mainAxisSlots);
    final others = currentItems.where((i) => i.id != draggingItem.id).toList();

    // If the target area is empty, accept immediately.
    if (!_hasConflicts(clamped, others)) {
      return DragResult(candidateRect: clamped);
    }

    // Find the most-overlapped item.
    LayoutItem? best;
    int bestArea = 0;
    for (final item in others) {
      final area = _overlapArea(clamped, item.rect);
      if (area > bestArea) {
        bestArea = area;
        best = item;
      }
    }
    if (best == null) return null;

    // Try to relocate the displaced item.
    final itemsWithoutBoth =
        others.where((i) => i.id != best!.id).toList();

    LayoutRect? relocatedRect;

    // Prefer a direct swap when sizes match.
    if (best.rect.size == draggingItem.rect.size &&
        !_hasConflicts(draggingItem.rect, itemsWithoutBoth)) {
      relocatedRect = draggingItem.rect;
    } else {
      // Use aggressive positioning to find a new slot for the displaced item.
      final maxCross = _computeMaxCrossSlots(others, axis);
      final positioner = DashboardAggressivePositioner(
        items: itemsWithoutBoth,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: maxCross,
      );
      final placed = positioner.position(best.id, best.rect.size);
      final newItem = placed.last;
      if (newItem.id == best.id) {
        relocatedRect = newItem.rect;
      }
    }

    if (relocatedRect == null) return null;

    return DragResult(
      candidateRect: best.rect,
      displacedItem: best,
      displacedRect: relocatedRect,
    );
  }

  @override
  List<LayoutItem> applyDrag({
    required LayoutItem draggingItem,
    required DragResult result,
    required List<LayoutItem> currentItems,
    required DashboardAxis axis,
    required int mainAxisSlots,
  }) {
    return currentItems.map((item) {
      if (item.id == draggingItem.id) {
        return LayoutItem(
          id: item.id,
          rect: result.candidateRect,
          minSize: item.minSize,
          maxSize: item.maxSize,
        );
      }
      if (result.displacedItem != null &&
          item.id == result.displacedItem!.id &&
          result.displacedRect != null) {
        return LayoutItem(
          id: item.id,
          rect: result.displacedRect!,
          minSize: item.minSize,
          maxSize: item.maxSize,
        );
      }
      return item;
    }).toList();
  }

  // ---------------------------------------------------------------------------

  int _overlapArea(LayoutRect a, LayoutRect b) {
    final ow = (a.right.clamp(b.left, b.right) -
            a.left.clamp(b.left, b.right))
        .clamp(0, 1 << 30);
    final oh = (a.bottom.clamp(b.top, b.bottom) -
            a.top.clamp(b.top, b.bottom))
        .clamp(0, 1 << 30);
    return ow * oh;
  }

  int _computeMaxCrossSlots(List<LayoutItem> items, DashboardAxis axis) {
    int max = 0;
    for (final item in items) {
      final v = axis == DashboardAxis.horizontal
          ? item.rect.bottom
          : item.rect.right;
      if (v > max) max = v;
    }
    return max;
  }
}
