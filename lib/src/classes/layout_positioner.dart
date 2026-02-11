import 'package:collection/collection.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';

enum PositionStrategy {
  aggressive,
  append,
  after,
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

  const DashboardAfterPositioner({
    required super.items,
    required super.axis,
    required this.mainAxisSlots,
    required this.maxCrossSlots,
    this.afterId,
    this.append = true,
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

    final shifted = <LayoutItem>{kept.last};

    for (final item in pending) {
      if (checkIfAffected(shifted, item.rect)) {
        kept = DashboardAppendPositioner(
          items: kept,
          axis: axis,
          mainAxisSlots: mainAxisSlots,
          maxCrossSlots: maxCrossSlots,
        ).position(item.id, item.rect.size);

        shifted.add(kept.last);
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

  /// if any shifted rect overlaps with the rect or comes before the rect in the layout order,
  /// it means the rect is affected by the shift and thus should also be shifted to the end of the layout.
  bool checkIfAffected(Iterable<LayoutItem> shiftedRects, LayoutRect rect) {
    for (final shifted in shiftedRects) {
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
      if (rect.compare(shifted.rect, axis) < 0) {
        return true;
      }

      if (shifted.rect.hasConflicts(rect)) {
        return true;
      }
    }

    return false;
  }
}
