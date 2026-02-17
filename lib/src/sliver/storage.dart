import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

abstract class DashboardItemStorage {
  DashboardAxis get axis;
  List<LayoutItem> get sortedItems;
  int get itemCount;
  int get maxCrossAxisSlots;
}

class DashboardLayoutController extends ChangeNotifier {
  final Map<Object, LayoutItem> _items;

  DashboardLayoutController({
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

  int _maxCrossAxisSlots = 0;
  int get maxCrossAxisSlots => _maxCrossAxisSlots;

  late List<LayoutItem> _sortedItems;
  List<LayoutItem> get sortedItems => List.unmodifiable(_sortedItems);

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

    final positioner = switch (strategy) {
      PositionStrategy.aggressive => DashboardAggressivePositioner(
        items: _items.values,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: maxCrossAxisSlots,
      ),
      PositionStrategy.append => DashboardAppendPositioner(
        items: _items.values,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: maxCrossAxisSlots,
      ),
      PositionStrategy.after => DashboardAfterPositioner(
        items: _items.values,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        afterId: afterId,
        maxCrossSlots: maxCrossAxisSlots,
      ),
      PositionStrategy.head => DashboardHeadPositioner(
        items: _items.values,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: maxCrossAxisSlots,
      ),
    };

    final newItems = positioner.position(id, validSize);

    _refillItems(newItems);

    notifyListeners();
  }

  /// Checks that the given items do not have any conflicts with each other.
  void _refillItems(Iterable<LayoutItem> items) {
    LayoutChecker.assertNoOverflow(items, axis, mainAxisSlots);
    LayoutChecker.assertNoConflicts(items);

    _items.clear();

    _maxCrossAxisSlots = 0;

    for (final item in items) {
      _items[item.id] = item;

      final crossAxisSlots = switch (axis) {
        DashboardAxis.horizontal => item.rect.bottom,
        DashboardAxis.vertical => item.rect.right,
      };

      if (crossAxisSlots > _maxCrossAxisSlots) {
        _maxCrossAxisSlots = crossAxisSlots;
      }
    }

    _sortedItems = DashboardHelper.sort(items, axis);
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
}
