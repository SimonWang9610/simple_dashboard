import 'package:simple_dashboard/simple_dashboard.dart';

sealed class LayoutShiftedArea {
  void addShiftedRect(LayoutRect rect);

  bool conflictWith(LayoutRect rect);

  factory LayoutShiftedArea.expanded(DashboardAxis axis) =>
      _ExpandedShiftedArea(axis);

  factory LayoutShiftedArea.sequential(DashboardAxis axis) =>
      _SequentialShiftedArea(axis);
}

final class _ExpandedShiftedArea implements LayoutShiftedArea {
  final DashboardAxis axis;
  int? _minX, _minY, _maxX, _maxY;
  LayoutRect? _earliestRect;

  _ExpandedShiftedArea(this.axis);

  @override
  void addShiftedRect(LayoutRect rect) {
    _minX = _minX == null
        ? rect.left
        : (_minX! < rect.left ? _minX : rect.left);
    _minY = _minY == null ? rect.top : (_minY! < rect.top ? _minY : rect.top);
    _maxX = _maxX == null
        ? rect.right
        : (_maxX! > rect.right ? _maxX : rect.right);
    _maxY = _maxY == null
        ? rect.bottom
        : (_maxY! > rect.bottom ? _maxY : rect.bottom);

    // Track the item that is "earliest" in the layout order to handle sequence preservation
    if (_earliestRect == null || rect.compare(_earliestRect!, axis) < 0) {
      _earliestRect = rect;
    }
  }

  @override
  bool conflictWith(LayoutRect rect) {
    if (_earliestRect == null) return false;

    // 1. Order Check: If the item was originally before the earliest shifted item,
    // it must be moved to maintain the sequence integrity.
    if (rect.compare(_earliestRect!, axis) < 0) {
      return true;
    }

    // 2. Conflict Check: Does the item overlap with the absorbed bounding box?
    return !(rect.right <= _minX! ||
        rect.left >= _maxX! ||
        rect.bottom <= _minY! ||
        rect.top >= _maxY!);
  }
}

final class _SequentialShiftedArea implements LayoutShiftedArea {
  final DashboardAxis axis;
  final List<LayoutRect> _shiftedRects = [];

  _SequentialShiftedArea(this.axis);

  @override
  void addShiftedRect(LayoutRect rect) {
    _shiftedRects.add(rect);
  }

  @override
  bool conflictWith(LayoutRect rect) {
    for (final shifted in _shiftedRects) {
      /// even this after rect is not overlapped with the shifted rect,
      /// it may still be affected if it is originally before the shifted rect on the layout,
      ///
      /// it means that the rect is not overlapped but it should come after the shifted rect in the layout order,
      /// as its ordering in the result list is affected by the shifted rect.
      ///
      /// for example, mainAxisFlex: 4
      /// [aaaa]
      /// [bb][cc]
      ///
      /// insert [dddd] at index 2,
      ///
      /// the rect origin ordering will be:
      /// [aaaa]
      /// [bb]
      /// [dddd]
      /// [cc]
      ///
      /// the list ordering will be [aaaa], [bb], [dddd], [cc],
      /// they are matched, as we promise the incoming rect to be placed at the given index
      ///
      /// if we DO NOT check the rect origin ordering and only check for overlaps, we will get the wrong result:
      ///
      /// rect origin ordering:
      /// [aaaa]
      /// [bb][cc]
      /// [dddd]
      ///
      /// but the list index ordering is [aaaa], [bb], [dddd], [cc]
      /// consequently the rect origin ordering is broken
      if (rect.compare(shifted, axis) < 0) {
        return true;
      }

      if (shifted.hasConflicts(rect)) {
        return true;
      }
    }

    return false;
  }
}
      // Check if the item was originally before the shifted item