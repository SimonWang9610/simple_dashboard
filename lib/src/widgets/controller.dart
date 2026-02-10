import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/classes/layout_engine.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/models/item.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';
import 'package:simple_dashboard/src/utils/helper.dart';

abstract class DashboardLayoutNotifier extends ChangeNotifier {
  DashboardLayoutNotifier({
    DashboardAxis axis = DashboardAxis.horizontal,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    required int mainAxisFlexCount,
  }) : _axis = axis,
       _mainAxisSpacing = mainAxisSpacing,
       _crossAxisSpacing = crossAxisSpacing,
       _mainAxisFlexCount = mainAxisFlexCount;

  int _mainAxisFlexCount = 0;
  int get mainAxisFlexCount => _mainAxisFlexCount;

  DashboardAxis _axis;
  DashboardAxis get axis => _axis;

  double _mainAxisSpacing;
  double get mainAxisSpacing => _mainAxisSpacing;
  set mainAxisSpacing(double value) {
    if (_mainAxisSpacing != value) {
      _mainAxisSpacing = value;
      notifyListeners();
    }
  }

  double _crossAxisSpacing;
  double get crossAxisSpacing => _crossAxisSpacing;
  set crossAxisSpacing(double value) {
    if (_crossAxisSpacing != value) {
      _crossAxisSpacing = value;
      notifyListeners();
    }
  }

  double get horizontalSpacing =>
      _axis == DashboardAxis.horizontal ? _mainAxisSpacing : _crossAxisSpacing;
  double get verticalSpacing =>
      _axis == DashboardAxis.horizontal ? _crossAxisSpacing : _mainAxisSpacing;
}

class DashboardController extends DashboardLayoutNotifier {
  final List<DashboardItem> _items;

  DashboardController({
    List<DashboardItem>? items,
    required super.mainAxisFlexCount,
    super.axis,
    super.mainAxisSpacing,
    super.crossAxisSpacing,
  }) : _items = items ?? <DashboardItem>[] {
    DashboardAssertion.assertIdNotDuplicate(_items);
    DashboardAssertion.assertRectsOrdered(rects, axis);
    DashboardAssertion.assertRectsNotOverlapped(rects);

    assert(
      () {
        for (final item in _items) {
          if (!DashboardAssertion.assertValidFlex(
            item.range,
            item.rect.flexes,
          )) {
            return false;
          }
        }

        return true;
      }(),
      "The initial flexes of all items must be within their specified ranges.",
    );
  }

  List<ItemRect> get rects => _items.map((item) => item.rect).toList();
  List<DashboardItem> get items => List.unmodifiable(_items);

  void addItem(Object id, ItemFlex flex, ItemFlexRange range) {
    assert(
      _items.every((item) => item.id != id),
      "The id of the new item must be unique.",
    );

    DashboardAssertion.assertValidFlex(range, flex);

    final (index, rect) = DashboardLayoutEngine.adoptRect(
      rects,
      flex,
      axis,
      mainAxisFlexCount,
    );

    final item = DashboardItem(
      id: id,
      rect: rect,
      range: range,
    );

    _items.insert(index, item);
    notifyListeners();
  }

  void removeItem(Object id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void reorderItem(int from, int to) {
    assert(
      from >= 0 && from < _items.length,
      "The old index must be within the bounds of the item list.",
    );

    assert(
      to >= 0 && to < _items.length,
      "The new index must be within the bounds of the item list.",
    );

    final shiftedIndex = from < to ? to - 1 : to;

    final item = _items.removeAt(from);

    final newRects = DashboardLayoutEngine.insertAt(
      rects,
      shiftedIndex,
      item.rect.flexes,
      axis,
      mainAxisFlexCount,
    );

    final newItem = DashboardItem(
      id: item.id,
      rect: newRects[shiftedIndex],
      range: item.range,
    );

    _items.insert(shiftedIndex, newItem);
    notifyListeners();
  }

  set mainAxisFlexCount(int value) {
    if (_mainAxisFlexCount == value) return;

    if (value < _mainAxisFlexCount) {
      DashboardAssertion.ensureMainAxisFlexNotExceedMax(items, value, axis);
    }

    _adoptItems(axis, value);
    _mainAxisFlexCount = value;
    notifyListeners();
  }

  set axis(DashboardAxis value) {
    if (_axis == value) return;

    _adoptItems(value, mainAxisFlexCount);
    _axis = value;
    notifyListeners();
  }

  void _adoptItems(DashboardAxis axis, int mainAxisFlexCount) {
    final newRects = <ItemRect>[];
    final newItems = <DashboardItem>[];

    for (final old in _items) {
      final rect = DashboardLayoutEngine.appendAtEnd(
        newRects,
        old.rect.flexes,
        axis,
        mainAxisFlexCount,
      );

      newItems.add(
        DashboardItem(
          id: old.id,
          rect: rect,
          range: old.range,
        ),
      );
    }

    _items
      ..clear()
      ..addAll(newItems);
  }
}
