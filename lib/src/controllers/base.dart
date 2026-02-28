import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

abstract mixin class DashboardMetricsManager {
  DashboardAxis get axis;
  int get mainAxisSlots;
  int get maxCrossAxisSlots;

  set mainAxisSlots(int value);
  set axis(DashboardAxis value);
}

abstract base class DashboardItemStorage
    with ChangeNotifier, DashboardMetricsManager {
  List<LayoutItem> get items;
  List<LayoutItem> get sortedItems;

  void updateItems(List<LayoutItem> newItems);

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

    updateItems(newItems);
  }

  void remove(Object id) {
    if (!items.any((item) => item.id == id)) {
      return;
    }

    final newItems = items.where((item) => item.id != id).toList();

    updateItems(newItems);
  }
}
