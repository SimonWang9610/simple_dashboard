import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/src/classes/layout_engine.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';

void main() {
  group("test adoptRect", () {
    test('adoptRect fills a gap in a horizontal layout', () {
      final axis = Axis.horizontal;
      final maxMainAxisFlex = 4; // 4 columns wide

      // Existing layout: [ (0,0, 1x1), EMPTY, (2,0, 2x1) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(2, 1)),
      ];

      final flexToAdopt = const ItemFlex(1, 1);

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(1, 0),
        const ItemFlex(1, 1),
      );
      expect(adopted, expectRect);
      expect(index, 1);
    });

    test('adoptRect jumps past a long obstacle (main axis)', () {
      final axis = Axis.horizontal;
      final maxMainAxisFlex = 4;

      // Obstacle: (0,0) with size 3x1.
      // Next item (size 1x1) cannot fit at x=0, 1, or 2.
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(3, 1)),
      ];

      final flexToAdopt = const ItemFlex(2, 1); // Too wide to fit at x=3

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(0, 1),
        const ItemFlex(2, 1),
      );

      expect(adopted, expectRect);
      expect(index, 1);
    });

    test('adoptRect jumps past a long obstacle (cross axis)', () {
      final axis = Axis.horizontal;
      final maxMainAxisFlex = 4;

      // Obstacle: (0,0) with size 1x3.
      // Next item (size 1x1) cannot fit at y=0, 1, or 2.
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 3)),
      ];

      final flexToAdopt = const ItemFlex(1, 1); // Too tall to fit at y=0

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(1, 0),
        const ItemFlex(1, 1),
      );

      expect(adopted, expectRect);
      expect(index, 1);
    });

    test("adoptRect fill the middle gap in a horizontal layout", () {
      final axis = Axis.horizontal;
      final maxMainAxisFlex = 6;

      // Existing layout: [ (0,0, 1x1), (2,0, 1x1), (4,0, 2x1) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(4, 0), const ItemFlex(2, 1)),
      ];

      final flexToAdopt = const ItemFlex(1, 1);

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(1, 0),
        const ItemFlex(1, 1),
      );

      expect(adopted, expectRect);
      expect(index, 1);
    });

    test("adoptRect fille the middle gap in the center area (1)", () {
      final axis = Axis.horizontal;
      final maxMainAxisFlex = 6;

      // Existing layout: [ (0,0, 1x1), (2,0, 1x1), (4,0, 2x1) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(4, 0), const ItemFlex(2, 1)),
        ItemRect(const ItemCoordinate(0, 1), const ItemFlex(1, 2)),
      ];

      final flexToAdopt = const ItemFlex(1, 2);

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(1, 0),
        const ItemFlex(1, 2),
      );

      expect(adopted, expectRect);
      expect(index, 1);
    });

    test("adoptRect fille the middle gap in the center area (2)", () {
      final axis = Axis.horizontal;
      final maxMainAxisFlex = 6;

      // Existing layout: [ (0,0, 1x1), (2,0, 1x1), (4,0, 2x1) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(4, 0), const ItemFlex(2, 1)),
        ItemRect(const ItemCoordinate(0, 1), const ItemFlex(1, 2)),
      ];

      final flexToAdopt = const ItemFlex(2, 2);

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(1, 1),
        const ItemFlex(2, 2),
      );

      expect(adopted, expectRect);
      expect(index, 4);
    });
  });
}
