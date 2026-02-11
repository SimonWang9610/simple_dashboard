import 'package:collection/collection.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/classes/shifted_area.dart';

enum PositionStrategy {
  /// fit the dashboard gap as much as possible
  aggressive,

  /// always place the item at the end of the layout
  append,

  /// place the item after the specified item.
  /// if no item is specified or the item is not found in the existing items,
  /// it will fallback as [append] or [head]
  /// according to the [DashboardAfterPositioner.append] flag.
  after,

  /// place the item at the start of the layout
  head,
}

sealed class DashboardPositioner {
  final Iterable<LayoutItem> items;
  final DashboardAxis axis;

  const DashboardPositioner({
    required this.items,
    required this.axis,
  });

  List<LayoutItem> position(Object id, LayoutSize size);
}

final class DashboardAggressivePositioner extends DashboardPositioner {
  final int mainAxisSlots;
  final int maxCrossSlots;
  final int crossSlotStart;
  final int mainSlotStart;

  const DashboardAggressivePositioner({
    required super.items,
    required super.axis,
    required this.mainAxisSlots,
    required this.maxCrossSlots,
    this.crossSlotStart = 0,
    this.mainSlotStart = 0,
  });

  @override
  List<LayoutItem> position(Object id, LayoutSize size) {
    assert(
      () {
        switch (axis) {
          case DashboardAxis.horizontal:
            return size.width <= mainAxisSlots;
          case DashboardAxis.vertical:
            return size.height <= mainAxisSlots;
        }
      }(),
      "item size cannot be larger than the maximum slot count of the main axis",
    );

    final maxMainSlots =
        mainAxisSlots -
        (axis == DashboardAxis.horizontal ? size.width : size.height);

    int mainSlot = mainSlotStart;

    for (
      int crossSlot = crossSlotStart;
      crossSlot <= maxCrossSlots;
      crossSlot++
    ) {
      while (mainSlot <= maxMainSlots) {
        final candidateRect = axis == DashboardAxis.horizontal
            ? LayoutRect(
                x: mainSlot,
                y: crossSlot,
                size: size,
              )
            : LayoutRect(
                x: crossSlot,
                y: mainSlot,
                size: size,
              );

        final conflictingItem = items.firstWhereOrNull(
          (item) => item.rect.hasConflicts(candidateRect),
        );

        if (conflictingItem == null) {
          return [
            ...items,
            LayoutItem(id: id, rect: candidateRect),
          ];
        }

        mainSlot = axis == DashboardAxis.horizontal
            ? conflictingItem.rect.right
            : conflictingItem.rect.bottom;
      }

      mainSlot = 0;
    }

    final newItem = LayoutItem(
      id: id,
      rect: axis == DashboardAxis.horizontal
          ? LayoutRect(
              x: 0,
              y: maxCrossSlots + 1,
              size: size,
            )
          : LayoutRect(
              x: maxCrossSlots + 1,
              y: 0,
              size: size,
            ),
    );

    return [
      ...items,
      newItem,
    ];
  }
}

final class DashboardAppendPositioner extends DashboardPositioner {
  final int mainAxisSlots;
  final int maxCrossSlots;

  const DashboardAppendPositioner({
    required super.items,
    required super.axis,
    required this.mainAxisSlots,
    required this.maxCrossSlots,
  });

  @override
  List<LayoutItem> position(Object id, LayoutSize size) {
    if (items.isEmpty) {
      return [
        LayoutItem(
          id: id,
          rect: LayoutRect(x: 0, y: 0, size: size),
        ),
      ];
    }

    final last = items.last;

    final internal = DashboardAggressivePositioner(
      items: items,
      axis: axis,
      mainAxisSlots: mainAxisSlots,
      maxCrossSlots: maxCrossSlots,
      crossSlotStart: axis == DashboardAxis.horizontal
          ? last.rect.top
          : last.rect.left,
      mainSlotStart: axis == DashboardAxis.horizontal
          ? last.rect.right
          : last.rect.bottom,
    );

    return internal.position(id, size);
  }
}

final class DashboardHeadPositioner extends DashboardAfterPositioner {
  const DashboardHeadPositioner({
    required super.items,
    required super.axis,
    required super.mainAxisSlots,
    required super.maxCrossSlots,
  }) : super(afterId: null, append: false);
}

final class DashboardAfterPositioner extends DashboardPositioner {
  final int mainAxisSlots;
  final int maxCrossSlots;
  final Object? afterId;
  final bool append;

  /// When `true`, the shifted area for checking conflicts
  /// will be expanded to a single bounding box that covers all shifted items,
  /// which can reduce the number of conflict checks but may cause more items to be shifted.
  ///
  /// When `false`, the shifted area will be the exact shapes of the shifted items,
  /// which can minimize unnecessary shifts but may require more conflict checks.
  final bool expandShiftCheckArea;

  const DashboardAfterPositioner({
    required super.items,
    required super.axis,
    required this.mainAxisSlots,
    required this.maxCrossSlots,
    this.afterId,
    this.append = true,
    this.expandShiftCheckArea = false,
  });

  @override
  List<LayoutItem> position(Object id, LayoutSize size) {
    assert(afterId != id, "An item cannot be positioned after itself.");

    final after = items.firstWhereOrNull((item) => item.id == afterId);

    if (after == null && append) {
      final appendPositioner = DashboardAppendPositioner(
        items: items,
        axis: axis,
        mainAxisSlots: mainAxisSlots,
        maxCrossSlots: maxCrossSlots,
      );

      return appendPositioner.position(id, size);
    }

    final sorted = DashboardAssertion.sort(items, axis);
    final afterIndex = after == null ? -1 : sorted.indexOf(after);

    List<LayoutItem> kept = <LayoutItem>[
      ...sorted.take(afterIndex + 1),
    ];

    final pending = <LayoutItem>[
      ...sorted.skip(afterIndex + 1),
    ];

    kept = DashboardAppendPositioner(
      items: kept,
      axis: axis,
      mainAxisSlots: mainAxisSlots,
      maxCrossSlots: maxCrossSlots,
    ).position(id, size);

    final shifted = expandShiftCheckArea
        ? LayoutShiftedArea.expanded(axis)
        : LayoutShiftedArea.sequential(axis);

    shifted.addShiftedRect(kept.last.rect);

    for (final item in pending) {
      if (shifted.conflictWith(item.rect)) {
        kept = DashboardAppendPositioner(
          items: kept,
          axis: axis,
          mainAxisSlots: mainAxisSlots,
          maxCrossSlots: maxCrossSlots,
        ).position(item.id, item.rect.size);

        shifted.addShiftedRect(kept.last.rect);
      } else {
        kept.add(item);
      }
    }

    assert(() {
      final keptIds = kept.map((e) => e.id).toSet();

      final originalIds = {
        ...items.map((e) => e.id),
        id,
      };

      return const SetEquality().equals(keptIds, originalIds.union({id}));
    }(), "Some items are missed");

    return kept;
  }

  bool conflictWith(List<LayoutItem> shifted, LayoutRect rect) {
    final area = expandShiftCheckArea
        ? LayoutShiftedArea.expanded(axis)
        : LayoutShiftedArea.sequential(axis);

    for (final item in shifted) {
      area.addShiftedRect(item.rect);
    }

    return area.conflictWith(rect);
  }
}
