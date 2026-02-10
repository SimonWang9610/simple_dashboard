import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/src/classes/layout_engine.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';

void main() {
  late DashboardAxis axis;

  group("[h] insertAt", () {
    setUp(() {
      axis = DashboardAxis.horizontal;
    });

    test("insert into an empty rect list", () {
      final rects = <ItemRect>[];
      final flex = ItemFlex(1, 1);
      final maxMainAxisFlex = 4;

      final neRects = DashboardLayoutEngine.insertAt(
        rects,
        0,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(neRects.length, 1);
      expect(neRects[0].origin, ItemCoordinate(0, 0));
      expect(neRects[0].flexes, flex);
    });

    test("insert to the middle of the list (shifted)", () {
      final maxMainAxisFlex = 4;

      final rects = [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(2, 1)),
        ItemRect(ItemCoordinate(2, 0), ItemFlex(2, 1)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(4, 1)),
      ];
      final flex = ItemFlex(1, 1);

      final result = DashboardLayoutEngine.insertAt(
        rects,
        1,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(result.length, 4);
      expect(result, [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(2, 1)),
        ItemRect(ItemCoordinate(2, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(2, 1)),
        ItemRect(ItemCoordinate(0, 2), ItemFlex(4, 1)),
      ]);
    });

    test("insert to the middle of the list (no shift)", () {
      final maxMainAxisFlex = 4;

      final rects = [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(2, 1)),
        ItemRect(ItemCoordinate(3, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(4, 1)),
      ];
      final flex = ItemFlex(1, 1);

      final result = DashboardLayoutEngine.insertAt(
        rects,
        1,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(result.length, 4);
      expect(result, [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(2, 1)),
        ItemRect(ItemCoordinate(2, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(3, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(4, 1)),
      ]);
    });

    test("insert to the middle of the list (long rect shifted)", () {
      final maxMainAxisFlex = 4;

      final rects = [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(1, 3)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(1, 2)),
      ];
      final flex = ItemFlex(1, 2);

      final result = DashboardLayoutEngine.insertAt(
        rects,
        1,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(result.length, 4);
      expect(result, [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(1, 2)),
        ItemRect(ItemCoordinate(2, 0), ItemFlex(1, 3)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(1, 2)),
      ]);
    });

    test("insert to the middle of the list (all shifted)", () {
      final maxMainAxisFlex = 3;

      final rects = [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(2, 2)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(1, 2)),
      ];
      final flex = ItemFlex(1, 1);

      final result = DashboardLayoutEngine.insertAt(
        rects,
        1,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(result.length, 4);
      expect(result, [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(2, 2)),
        ItemRect(ItemCoordinate(2, 1), ItemFlex(1, 2)),
      ]);
    });

    test("insert to the middle of the list (last shifted)", () {
      final maxMainAxisFlex = 3;

      final rects = [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(2, 2)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(1, 2)),
      ];
      final flex = ItemFlex(1, 1);

      final result = DashboardLayoutEngine.insertAt(
        rects,
        2,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(result.length, 4);
      expect(result, [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(2, 2)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 2), ItemFlex(1, 2)),
      ]);
    });
  });

  group("[v] insertAt", () {
    setUp(() {
      axis = DashboardAxis.vertical;
    });

    test("insert into an empty list", () {
      final rects = <ItemRect>[];
      final flex = ItemFlex(1, 1);
      final maxMainAxisFlex = 4;

      final neRects = DashboardLayoutEngine.insertAt(
        rects,
        0,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(neRects.length, 1);
      expect(neRects[0].origin, ItemCoordinate(0, 0));
      expect(neRects[0].flexes, flex);
    });

    test("insert to the middle of the list (shifted)", () {
      final maxMainAxisFlex = 4;

      final rects = [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 2)),
        ItemRect(ItemCoordinate(0, 2), ItemFlex(1, 2)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(1, 4)),
      ];
      final flex = ItemFlex(1, 1);

      final result = DashboardLayoutEngine.insertAt(
        rects,
        1,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(result.length, 4);
      expect(result, [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 2)),
        ItemRect(ItemCoordinate(0, 2), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(1, 2)),
        ItemRect(ItemCoordinate(2, 0), ItemFlex(1, 4)),
      ]);
    });

    test("insert to the middle of the list (no shift)", () {
      final maxMainAxisFlex = 4;

      final rects = [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 2)),
        ItemRect(ItemCoordinate(0, 3), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(1, 4)),
      ];
      final flex = ItemFlex(1, 1);

      final result = DashboardLayoutEngine.insertAt(
        rects,
        1,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(result.length, 4);
      expect(result, [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 2)),
        ItemRect(ItemCoordinate(0, 2), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 3), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(1, 4)),
      ]);
    });

    test("insert into the middle of the list (long rect shifted)", () {
      final maxMainAxisFlex = 4;

      final rects = [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(3, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(2, 1)),
      ];
      final flex = ItemFlex(1, 1);

      final result = DashboardLayoutEngine.insertAt(
        rects,
        1,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(result.length, 4);
      expect(result, [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 2), ItemFlex(3, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(2, 1)),
      ]);
    });

    test("insert to the middle of the list (all shifted)", () {
      final maxMainAxisFlex = 3;

      final rects = [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(2, 2)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(2, 1)),
      ];
      final flex = ItemFlex(1, 1);

      final result = DashboardLayoutEngine.insertAt(
        rects,
        1,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(result.length, 4);
      expect(result, [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(2, 2)),
        ItemRect(ItemCoordinate(1, 2), ItemFlex(2, 1)),
      ]);
    });

    test("insert to the middle of the list (last shifted)", () {
      final maxMainAxisFlex = 3;

      final rects = [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(2, 2)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(2, 1)),
      ];
      final flex = ItemFlex(1, 1);

      final result = DashboardLayoutEngine.insertAt(
        rects,
        2,
        flex,
        axis,
        maxMainAxisFlex,
      );

      expect(result.length, 4);
      expect(result, [
        ItemRect(ItemCoordinate(0, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(0, 1), ItemFlex(2, 2)),
        ItemRect(ItemCoordinate(1, 0), ItemFlex(1, 1)),
        ItemRect(ItemCoordinate(2, 0), ItemFlex(2, 1)),
      ]);
    });
  });
}
