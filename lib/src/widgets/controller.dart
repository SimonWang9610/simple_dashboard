import 'package:flutter/foundation.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/classes/layout_positioner.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';

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
    _refillItems(items);
  }

  DashboardAxis _axis;
  DashboardAxis get axis => _axis;
  set axis(DashboardAxis value) {
    if (_axis != value) {
      _axis = value;
      notifyListeners();
    }
  }

  int _mainAxisSlots;
  int get mainAxisSlots => _mainAxisSlots;
  set mainAxisSlots(int value) {
    if (_mainAxisSlots != value) {
      final oldSlots = _mainAxisSlots;
      _mainAxisSlots = value;

      if (_mainAxisSlots < oldSlots) {
        _reAdoptMainAxisSlots();
      }

      notifyListeners();
    }
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
    assert(
      strategy != PositionStrategy.after || afterId != null,
      "afterId must be provided when using PositionStrategy.after",
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

  Map<CollisionDirection, List<LayoutItem>> checkCollisions(LayoutRect rect) {
    final conflicts = _items.values.where(
      (item) => item.rect.hasConflicts(rect) && item.rect != rect,
    );

    final Map<CollisionDirection, List<LayoutItem>> result = {};

    for (final item in conflicts) {
      final itemRect = item.rect;

      final isTop = rect.top < itemRect.top;
      final isLeft = rect.left < itemRect.left;

      final direction = switch (isTop) {
        true => switch (isLeft) {
          true => CollisionDirection.topLeft,
          false => CollisionDirection.topRight,
        },
        false => switch (isLeft) {
          true => CollisionDirection.bottomLeft,
          false => CollisionDirection.bottomRight,
        },
      };

      result.putIfAbsent(direction, () => []).add(item);
    }

    return result;
  }

  // TODO: re-adopt all items to the new main axis slots
  void _reAdoptMainAxisSlots() {}

  void _refillItems(Iterable<LayoutItem> items) {
    DashboardAssertion.checkNoOverflow(items, axis, mainAxisSlots);
    DashboardAssertion.checkNoConflict(items);

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
