import 'package:flutter/foundation.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

class DashboardController extends ChangeNotifier {
  final Map<Object, LayoutItem> _items;

  late int _maxX = 0;
  late int _maxY = 0;

  int get _maxCrossSlots => axis == DashboardAxis.horizontal ? _maxY : _maxX;

  DashboardController({
    DashboardAxis axis = DashboardAxis.horizontal,
    required int mainAxisSlots,
    Iterable<LayoutItem> items = const [],
  }) : _axis = axis,
       _mainAxisSlots = mainAxisSlots,
       _items = {} {
    /// ensure the initial items are valid and properly adopted
    final adopted = DashboardHelper.adoptMetrics(
      items,
      axis,
      mainAxisSlots,
    );

    _refillItems(adopted);
  }

  DashboardAxis _axis;
  DashboardAxis get axis => _axis;
  set axis(DashboardAxis value) {
    _updateMetrics(value, null);
  }

  int _mainAxisSlots;
  int get mainAxisSlots => _mainAxisSlots;
  set mainAxisSlots(int value) {
    _updateMetrics(null, value);
  }

  List<LayoutItem> get items => _items.values.toList();

  void addItem(
    Object id,
    LayoutSize size, {
    required PositionStrategy strategy,
    Object? afterId,
  }) {
    assert(
      !_items.containsKey(id),
      "Each item in the dashboard must have a unique id. An item with id [$id] already exists.",
    );

    final validSize = size.constrain(axis, mainAxisSlots);

    final DashboardPositioner positioner = switch (strategy) {
      PositionStrategy.aggressive => DashboardAggressivePositioner(
        items: _items.values,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: _maxCrossSlots,
      ),
      PositionStrategy.append => DashboardAppendPositioner(
        items: _items.values,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: _maxCrossSlots,
      ),
      PositionStrategy.after => DashboardAfterPositioner(
        items: _items.values,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        afterId: afterId,
        maxCrossSlots: _maxCrossSlots,
      ),
      PositionStrategy.head => DashboardHeadPositioner(
        items: _items.values,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: _maxCrossSlots,
      ),
    };

    final newItems = positioner.position(id, validSize);

    _refillItems(newItems);

    notifyListeners();
  }

  void removeItem(Object id) {
    final removed = _items.remove(id);

    if (removed == null) return;

    /// update maxX and maxY after removal
    if (removed.rect.right == _maxX || removed.rect.bottom == _maxY) {
      _maxX = 0;
      _maxY = 0;

      for (final item in _items.values) {
        if (item.rect.right > _maxX) {
          _maxX = item.rect.right;
        }

        if (item.rect.bottom > _maxY) {
          _maxY = item.rect.bottom;
        }
      }
    }

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

    int? oldMainAxisSlots;

    if (newMainAxisSlots != null && newMainAxisSlots != mainAxisSlots) {
      oldMainAxisSlots = _mainAxisSlots;
      _mainAxisSlots = newMainAxisSlots;
      shouldReAdopt = true;
    }

    if (shouldReAdopt) {
      final adoptedItems = DashboardHelper.adoptMetrics(
        _items.values,
        axis,
        mainAxisSlots,
        oldMainAxisSlots: oldMainAxisSlots,
      );
      _refillItems(adoptedItems);
      notifyListeners();
    }
  }

  /// Checks that the given items do not have any conflicts with each other.
  void _refillItems(Iterable<LayoutItem> items) {
    LayoutChecker.assertNoOverflow(items, axis, mainAxisSlots);
    LayoutChecker.assertNoConflicts(items);

    _items.clear();

    _maxX = 0;
    _maxY = 0;

    for (final item in items) {
      _items[item.id] = item;

      if (item.rect.right > _maxX) {
        _maxX = item.rect.right;
      }

      if (item.rect.bottom > _maxY) {
        _maxY = item.rect.bottom;
      }
    }
  }
}
