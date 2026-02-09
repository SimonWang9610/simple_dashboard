import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/src/classes/layout_engine.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';

void main() async {
  late DashboardAxis axis;

  group("[h] DashboardLayoutEngine.appendAtEnd", () {
    setUp(() {
      axis = DashboardAxis.horizontal;
    });

    test("append directly", () {
      final mainAxisFlex = 4;

      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(2, 1)),
      ];

      final adopted = DashboardLayoutEngine.appendAtEnd(
        rects,
        const ItemFlex(2, 1),
        axis,
        mainAxisFlex,
      );

      expect(
        adopted,
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(2, 1)),
      );

      expect(rects, [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(2, 1)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(2, 1)),
      ]);
    });

    test("append when there is a fillable gap", () {
      final mainAxisFlex = 4;

      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(2, 1)),
      ];

      final adopted = DashboardLayoutEngine.appendAtEnd(
        rects,
        const ItemFlex(1, 1),
        axis,
        mainAxisFlex,
      );

      expect(
        adopted,
        ItemRect(const ItemCoordinate(0, 1), const ItemFlex(1, 1)),
      );

      expect(rects, [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(2, 1)),
        ItemRect(const ItemCoordinate(0, 1), const ItemFlex(1, 1)),
      ]);
    });

    test("append when a long rect is an obstacle", () {
      final mainAxisFlex = 4;

      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 2)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(2, 1)),
      ];

      final adopted = DashboardLayoutEngine.appendAtEnd(
        rects,
        const ItemFlex(1, 1),
        axis,
        mainAxisFlex,
      );

      expect(
        adopted,
        ItemRect(const ItemCoordinate(1, 1), const ItemFlex(1, 1)),
      );

      expect(rects, [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 2)),
        ItemRect(const ItemCoordinate(2, 0), const ItemFlex(2, 1)),
        ItemRect(const ItemCoordinate(1, 1), const ItemFlex(1, 1)),
      ]);
    });

    test("append when the long rect is in the middle", () {
      final mainAxisFlex = 4;

      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(1, 2)),
        ItemRect(const ItemCoordinate(3, 0), const ItemFlex(1, 1)),
      ];

      final adopted = DashboardLayoutEngine.appendAtEnd(
        rects,
        const ItemFlex(1, 1),
        axis,
        mainAxisFlex,
      );

      expect(
        adopted,
        ItemRect(const ItemCoordinate(0, 1), const ItemFlex(1, 1)),
      );

      expect(rects, [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(1, 2)),
        ItemRect(const ItemCoordinate(3, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 1), const ItemFlex(1, 1)),
      ]);
    });
  });

  group("[v] DashboardLayoutEngine.appendAtEnd", () {
    setUp(() {
      axis = DashboardAxis.vertical;
    });

    test("append directly", () {
      final mainAxisFlex = 4;

      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 2)),
      ];

      final adopted = DashboardLayoutEngine.appendAtEnd(
        rects,
        const ItemFlex(1, 2),
        axis,
        mainAxisFlex,
      );

      expect(
        adopted,
        ItemRect(const ItemCoordinate(0, 2), const ItemFlex(1, 2)),
      );

      expect(rects, [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 2)),
        ItemRect(const ItemCoordinate(0, 2), const ItemFlex(1, 2)),
      ]);
    });

    test("append when there is a fillable gap", () {
      final mainAxisFlex = 4;

      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 2), const ItemFlex(1, 2)),
      ];

      final adopted = DashboardLayoutEngine.appendAtEnd(
        rects,
        const ItemFlex(1, 1),
        axis,
        mainAxisFlex,
      );

      expect(
        adopted,
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(1, 1)),
      );

      expect(rects, [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 2), const ItemFlex(1, 2)),
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(1, 1)),
      ]);
    });

    test("append when a long rect is an obstacle", () {
      final mainAxisFlex = 4;

      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(2, 1)),
        ItemRect(const ItemCoordinate(0, 2), const ItemFlex(1, 2)),
      ];

      final adopted = DashboardLayoutEngine.appendAtEnd(
        rects,
        const ItemFlex(1, 1),
        axis,
        mainAxisFlex,
      );

      expect(
        adopted,
        ItemRect(const ItemCoordinate(1, 1), const ItemFlex(1, 1)),
      );

      expect(rects, [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(2, 1)),
        ItemRect(const ItemCoordinate(0, 2), const ItemFlex(1, 2)),
        ItemRect(const ItemCoordinate(1, 1), const ItemFlex(1, 1)),
      ]);
    });

    test("append when the ong rect is in the middle", () {
      final mainAxisFlex = 4;

      final rects = [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 1), const ItemFlex(2, 1)),
        ItemRect(const ItemCoordinate(0, 3), const ItemFlex(1, 1)),
      ];

      final adopted = DashboardLayoutEngine.appendAtEnd(
        rects,
        const ItemFlex(1, 1),
        axis,
        mainAxisFlex,
      );

      expect(
        adopted,
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(1, 1)),
      );

      expect(rects, [
        ItemRect(const ItemCoordinate(0, 0), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(0, 1), const ItemFlex(2, 1)),
        ItemRect(const ItemCoordinate(0, 3), const ItemFlex(1, 1)),
        ItemRect(const ItemCoordinate(1, 0), const ItemFlex(1, 1)),
      ]);
    });
  });
}
