import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

abstract class DashboardController extends ChangeNotifier {
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

    assert(
      newItems.length == items.length - 1,
      "Exactly one item should be removed.",
    );

    items = newItems;
  }

  factory DashboardController({
    DashboardAxis axis,
    required int mainAxisSlots,
    Iterable<LayoutItem>? initialItems,
  }) = _DashboardControllerImpl;
}

class _DashboardControllerImpl extends DashboardController {
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
  List<LayoutItem> get items => List.unmodifiable(_items);

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

    int? oldMainAxisSlots;

    if (newMainAxisSlots != null && newMainAxisSlots != mainAxisSlots) {
      oldMainAxisSlots = _mainAxisSlots;
      _mainAxisSlots = newMainAxisSlots;
      shouldReAdopt = true;
    }

    if (shouldReAdopt) {
      final adoptedItems = DashboardHelper.adoptMetrics(
        items,
        axis,
        mainAxisSlots,
        oldMainAxisSlots: oldMainAxisSlots,
      );
      _refillItems(adoptedItems);
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

    _items = items.toList();
    _sortedItems = null;

    notifyListeners();
  }
}
