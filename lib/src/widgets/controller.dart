import 'package:flutter/foundation.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

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
        _items.values,
        axis,
        mainAxisSlots,
      );
      _refillItems(adoptedItems);
      notifyListeners();
    }
  }

  /// Checks that the given items do not have any conflicts with each other.
  void _refillItems(Iterable<LayoutItem> items) {
    DashboardHelper.checkNoOverflow(items, axis, mainAxisSlots);
    DashboardHelper.checkNoConflict(items);

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
