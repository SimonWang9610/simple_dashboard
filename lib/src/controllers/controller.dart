import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

final class DashboardController extends DashboardItemStorage
    with DashboardItemMutator {
  DashboardController({
    DashboardAxis axis = DashboardAxis.horizontal,
    required int mainAxisSlots,
    Iterable<LayoutItem>? initialItems,
  }) : _axis = axis,
       _mainAxisSlots = mainAxisSlots {
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
  void updateItems(List<LayoutItem> newItems) {
    _refillItems(newItems);
    notifyListeners();
  }

  @override
  bool validLayoutRect(LayoutRect rect) {
    return LayoutChecker.isValidRect(rect, axis, mainAxisSlots);
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
