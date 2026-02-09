import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/src/classes/layout_engine.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';

void main() {
  group("test adoptRect (horizontal)", () {
    test('[h] adoptRect fills a gap ', () {
      final axis = DashboardAxis.horizontal;
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

    test('[h] adoptRect jumps past a long obstacle (main axis)', () {
      final axis = DashboardAxis.horizontal;
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

    test('[h] adoptRect jumps past a long obstacle (cross axis)', () {
      final axis = DashboardAxis.horizontal;
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

    test("[h] adoptRect fill the middle gap in a horizontal layout", () {
      final axis = DashboardAxis.horizontal;
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

    test("[h] adoptRect fille the middle gap in the center area (1)", () {
      final axis = DashboardAxis.horizontal;
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

    test("[h] adoptRect fille the middle gap in the center area (2)", () {
      final axis = DashboardAxis.horizontal;
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

    test("[h] fill the wrapped hole", () {
      final axis = DashboardAxis.horizontal;
      final maxMainAxisFlex = 4;

      // Existing layout: [ (0,0, 1x1), (2,0, 1x1), (4,0, 2x1) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(3, 1)),
        ItemRect(const ItemCoordinate(0, 1), const ItemFlex(1, 2)),
        ItemRect(const ItemCoordinate(2, 1), const ItemFlex(2, 1)),
        ItemRect(const ItemCoordinate(1, 2), const ItemFlex(2, 1)),
      ];

      final flexToAdopt = const ItemFlex(1, 1);

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(1, 1),
        const ItemFlex(1, 1),
      );

      expect(adopted, expectRect);
      expect(index, 3);
    });

    test("[h] jump the long rect (1)", () {
      final axis = DashboardAxis.horizontal;
      final maxMainAxisFlex = 3;

      // Existing layout: [ (0,0, 3x1) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(1, 3)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(1, 1)),
      ];

      final flexToAdopt = const ItemFlex(1, 1);

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(0, 1),
        const ItemFlex(1, 1),
      );

      expect(adopted, expectRect);
      expect(index, 3);
    });

    test("[h] jump the long rect (2): restrict search area", () {
      final axis = DashboardAxis.horizontal;
      final maxMainAxisFlex = 3;

      // Existing layout: [ (0,0, 3x1) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(1, 3)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(1, 1)),
      ];

      final last = rects.last;

      final flexToAdopt = const ItemFlex(1, 1);

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
        crossStart: last.top,
        mainStart: last.right,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(0, 1),
        const ItemFlex(1, 1),
      );

      expect(adopted, expectRect);
      expect(index, 3);
    });
  });

  group("adoptRect (vertical)", () {
    test('[v] adoptRect fills a gap in a vertical layout', () {
      final axis = DashboardAxis.vertical;
      final maxMainAxisFlex = 4; // 4 rows tall

      // Existing layout: [ (0,0, 1x1), EMPTY, (0,2, 1x2) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 2), const ItemFlex(1, 2)),
      ];

      final flexToAdopt = const ItemFlex(1, 1);

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(0, 1),
        const ItemFlex(1, 1),
      );
      expect(adopted, expectRect);
      expect(index, 1);
    });

    test('[v] adoptRect jumps past a long obstacle (main axis)', () {
      final axis = DashboardAxis.vertical;
      final maxMainAxisFlex = 4;

      // Obstacle: (0,0) with size 1x3.
      // Next item (size 1x1) cannot fit at y=0, 1, or 2.
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 3)),
      ];

      final flexToAdopt = const ItemFlex(1, 2); // Too tall to fit at y=3

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

    test('[v] adoptRect jumps past a long obstacle (cross axis)', () {
      final axis = DashboardAxis.vertical;
      final maxMainAxisFlex = 4;

      // Obstacle: (0,0) with size 3x1.
      // Next item (size 1x1) cannot fit at x=0, 1, or 2.
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(3, 1)),
      ];

      final flexToAdopt = const ItemFlex(1, 1); // Too wide to fit at x=3

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(0, 1),
        const ItemFlex(1, 1),
      );

      expect(adopted, expectRect);
      expect(index, 1);
    });

    test("[v] adoptRect fill the middle gap in a vertical layout", () {
      final axis = DashboardAxis.vertical;
      final maxMainAxisFlex = 6;

      // Existing layout: [ (0,0, 1x1), (0,2, 1x1), (0,4, 1x2) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 2), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 4), const ItemFlex(1, 2)),
      ];

      final flexToAdopt = const ItemFlex(1, 1);

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(0, 1),
        const ItemFlex(1, 1),
      );

      expect(adopted, expectRect);
      expect(index, 1);
    });

    test("[v] adoptRect fille the middle gap in the center area (1)", () {
      final axis = DashboardAxis.vertical;
      final maxMainAxisFlex = 6;

      // Existing layout: [ (0,0, 1x1), (0,2, 1x1), (0,4, 1x2) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 2), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 4), const ItemFlex(1, 2)),
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(2, 1)),
      ];

      final flexToAdopt = const ItemFlex(2, 1);

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

    test("[v] adoptRect fille the middle gap in the center area (2)", () {
      final axis = DashboardAxis.vertical;
      final maxMainAxisFlex = 6;

      // Existing layout: [ (0,0, 1x1), (0,2, 1x1), (0,4, 1x2) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 2), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 4), const ItemFlex(1, 2)),
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(2, 1)),
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

    test("[v] fill the wrapped hole", () {
      final axis = DashboardAxis.vertical;
      final maxMainAxisFlex = 4;

      // Existing layout: [ (0,0, 1x1), (0,1, 3x1), (0,2, 1x2), (2,1, 2x1), (1,2, 2x1) ]
      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 1), const ItemFlex(1, 3)),
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(1, 2)),
        ItemRect(const ItemCoordinate(1, 3), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(1, 3)),
      ];

      final flexToAdopt = const ItemFlex(1, 1);

      final (index, adopted) = DashboardLayoutEngine.adoptRect(
        rects,
        flexToAdopt,
        axis,
        maxMainAxisFlex,
      );

      final expectRect = ItemRect(
        const ItemCoordinate(1, 2),
        const ItemFlex(1, 1),
      );

      expect(adopted, expectRect);
      expect(index, 3);
    });
  });
}
