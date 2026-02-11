import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

void main() {
  group('DashboardAggressivePositioner Tests', () {
    test('should place item in first available slot', () {
      final items = <LayoutItem>[];
      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item1',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 1);
      expect(result[0].id, 'item1');
      expect(result[0].rect.x, 0);
      expect(result[0].rect.y, 0);
      expect(result[0].rect.size.width, 2);
      expect(result[0].rect.size.height, 1);
    });

    test('should place item after existing item in horizontal layout', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 2);
      expect(result[1].id, 'item2');
      expect(result[1].rect.x, 2);
      expect(result[1].rect.y, 0);
    });

    test('should place item in next row when current row is full', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 4, height: 1)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 2);
      expect(result[1].id, 'item2');
      expect(result[1].rect.x, 0);
      expect(result[1].rect.y, 1);
    });

    test('should fill gaps aggressively in horizontal layout', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 0, y: 1, size: LayoutSize(width: 4, height: 1)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item3',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 3);
      expect(result[2].id, 'item3');
      expect(result[2].rect.x, 2);
      expect(result[2].rect.y, 0);
    });

    test('should work with vertical axis', () {
      final items = <LayoutItem>[];
      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.vertical,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item1',
        LayoutSize(width: 1, height: 2),
      );

      expect(result.length, 1);
      expect(result[0].id, 'item1');
      expect(result[0].rect.x, 0);
      expect(result[0].rect.y, 0);
    });

    test(
      'should place item in new cross slot when all existing cross slots are full',
      () {
        final items = [
          LayoutItem(
            id: 'item1',
            rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 4, height: 1)),
          ),
          LayoutItem(
            id: 'item2',
            rect: LayoutRect(x: 0, y: 1, size: LayoutSize(width: 4, height: 1)),
          ),
          LayoutItem(
            id: 'item3',
            rect: LayoutRect(x: 0, y: 2, size: LayoutSize(width: 4, height: 1)),
          ),
          LayoutItem(
            id: 'item4',
            rect: LayoutRect(x: 0, y: 3, size: LayoutSize(width: 4, height: 1)),
          ),
          LayoutItem(
            id: 'item5',
            rect: LayoutRect(x: 0, y: 4, size: LayoutSize(width: 4, height: 1)),
          ),
        ];

        final positioner = DashboardAggressivePositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 4,
          maxCrossSlots: 4,
        );

        final result = positioner.position(
          'item6',
          LayoutSize(width: 2, height: 1),
        );

        expect(result.length, 6);
        expect(result[5].id, 'item6');
        expect(result[5].rect.y, 5);
        expect(result[5].rect.x, 0);
      },
    );

    test('should respect crossSlotStart parameter', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
        crossSlotStart: 1,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 2);
      expect(result[1].rect.y, 1);
    });

    test('should respect mainSlotStart parameter', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
        mainSlotStart: 2,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 2);
      expect(result[1].rect.x, 2);
      expect(result[1].rect.y, 0);
    });
  });

  group('DashboardAppendPositioner Tests', () {
    test('should place first item at origin', () {
      final items = <LayoutItem>[];
      final positioner = DashboardAppendPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item1',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 1);
      expect(result[0].rect.x, 0);
      expect(result[0].rect.y, 0);
    });

    test('should append item after last item in horizontal layout', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardAppendPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 2);
      expect(result[1].id, 'item2');
      expect(result[1].rect.x, 2);
      expect(result[1].rect.y, 0);
    });

    test('should move to next row when appending would exceed main axis', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 3, height: 1)),
        ),
      ];

      final positioner = DashboardAppendPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 2);
      expect(result[1].rect.x, 0);
      expect(result[1].rect.y, 1);
    });

    test('should work with vertical axis', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 1, height: 2)),
        ),
      ];

      final positioner = DashboardAppendPositioner(
        items: items,
        axis: DashboardAxis.vertical,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 1, height: 2),
      );

      expect(result.length, 2);
      expect(result[1].rect.y, 2);
    });
  });

  group('DashboardAfterPositioner Tests', () {
    test('should place item after specified item', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 2, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardAfterPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
        afterId: 'item1',
      );

      final result = positioner.position(
        'item3',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 3);
      final item3Index = result.indexWhere((item) => item.id == 'item3');
      final item1Index = result.indexWhere((item) => item.id == 'item1');
      final item2Index = result.indexWhere((item) => item.id == 'item2');

      expect(item3Index, greaterThan(item1Index));
      expect(result[item3Index].rect.x, 2);
      expect(result[item3Index].rect.y, 0);
      expect(result[item2Index].rect.x, 0);
      expect(result[item2Index].rect.y, 1);
    });

    test('should shift affected items', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 2, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardAfterPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
        afterId: 'item1',
      );

      final result = positioner.position(
        'item3',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 3);
      final item2 = result.firstWhere((item) => item.id == 'item2');
      expect(item2.rect.y, 1);
      expect(item2.rect.x, 0);
    });

    test(
      'should fallback to append when afterId is null and append is true',
      () {
        final items = [
          LayoutItem(
            id: 'item1',
            rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
          ),
        ];

        final positioner = DashboardAfterPositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 4,
          maxCrossSlots: 4,
          afterId: null,
          append: true,
        );

        final result = positioner.position(
          'item2',
          LayoutSize(width: 2, height: 1),
        );

        expect(result.length, 2);
        expect(result[1].rect.x, 2);
      },
    );

    test(
      'should fallback to append when afterId is not found and append is true',
      () {
        final items = [
          LayoutItem(
            id: 'item1',
            rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
          ),
        ];

        final positioner = DashboardAfterPositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 4,
          maxCrossSlots: 4,
          afterId: 'nonexistent',
          append: true,
        );

        final result = positioner.position(
          'item2',
          LayoutSize(width: 2, height: 1),
        );

        expect(result.length, 2);
        expect(result[1].rect.x, 2);
      },
    );

    test('should place at head when afterId is null and append is false', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardAfterPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
        afterId: null,
        append: false,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 2);
      expect(result[0].id, 'item2');
      expect(result[0].rect.x, 0);
      expect(result[0].rect.y, 0);
      expect(result[1].rect.x, 2);
      expect(result[1].rect.y, 0);
    });

    test('checkIfAffected should detect overlapping items', () {
      final positioner = DashboardAfterPositioner(
        items: [],
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final shiftedItems = [
        LayoutItem(
          id: 'shifted',
          rect: LayoutRect(x: 2, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final testRect = LayoutRect(
        x: 2,
        y: 0,
        size: LayoutSize(width: 2, height: 1),
      );

      expect(positioner.conflictWith(shiftedItems, testRect), isTrue);
    });

    test(
      'checkIfAffected should detect items that come before shifted items',
      () {
        final positioner = DashboardAfterPositioner(
          items: [],
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 4,
          maxCrossSlots: 4,
        );

        final shiftedItems = [
          LayoutItem(
            id: 'shifted',
            rect: LayoutRect(x: 0, y: 1, size: LayoutSize(width: 2, height: 1)),
          ),
        ];

        final testRect = LayoutRect(
          x: 2,
          y: 0,
          size: LayoutSize(width: 2, height: 1),
        );

        expect(positioner.conflictWith(shiftedItems, testRect), isTrue);
      },
    );

    test('should preserve all items after positioning', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 2, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
        LayoutItem(
          id: 'item3',
          rect: LayoutRect(x: 0, y: 1, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardAfterPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
        afterId: 'item1',
      );

      final result = positioner.position(
        'item4',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 4);
      final ids = result.map((item) => item.id).toSet();
      expect(ids, containsAll(['item1', 'item2', 'item3', 'item4']));
      expect(result[2].rect.y, 1);
      expect(result[2].rect.x, 0);
      expect(result[3].rect.y, 1);
      expect(result[3].rect.x, 2);
    });
  });

  group('DashboardHeadPositioner Tests', () {
    test('should place item at the head of the layout', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardHeadPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 2);
      expect(result[0].id, 'item2');
      expect(result[1].id, 'item1');
    });

    test('should shift all existing items', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 2, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardHeadPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item3',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 3);
      expect(result[0].id, 'item3');
      expect(result[0].rect.x, 0);
      expect(result[0].rect.y, 0);
    });
  });

  group('Edge Cases and Error Handling', () {
    test('should handle empty items list', () {
      final positioner = DashboardAggressivePositioner(
        items: [],
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item1',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 1);
      expect(result[0].rect.x, 0);
      expect(result[0].rect.y, 0);
    });

    test('should handle single slot items', () {
      final positioner = DashboardAggressivePositioner(
        items: [],
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item1',
        LayoutSize(width: 1, height: 1),
      );

      expect(result.length, 1);
      expect(result[0].rect.size.width, 1);
      expect(result[0].rect.size.height, 1);
    });

    test('should handle maximum size items', () {
      final positioner = DashboardAggressivePositioner(
        items: [],
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item1',
        LayoutSize(width: 4, height: 1),
      );

      expect(result.length, 1);
      expect(result[0].rect.size.width, 4);
    });

    test('should handle complex layouts with multiple gaps', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 0, y: 1, size: LayoutSize(width: 1, height: 1)),
        ),
        LayoutItem(
          id: 'item3',
          rect: LayoutRect(x: 2, y: 1, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item4',
        LayoutSize(width: 1, height: 1),
      );

      expect(result.length, 4);
      final item4 = result.firstWhere((item) => item.id == 'item4');
      expect(item4.rect.x, 2);
      expect(item4.rect.y, 0);
    });

    test('should handle items with height > 1 in horizontal layout', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 2)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 2);
      expect(result[1].rect.x, 2);
      expect(result[1].rect.y, 0);
    });

    test('should handle items with width > 1 in vertical layout', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 2)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.vertical,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 1, height: 2),
      );

      expect(result.length, 2);
      expect(result[1].rect.x, 0);
      expect(result[1].rect.y, 2);
    });

    test('should handle zero maxCrossSlots boundary', () {
      final positioner = DashboardAggressivePositioner(
        items: [],
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 0,
      );

      final result = positioner.position(
        'item1',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 1);
      expect(result[0].rect.y, 0);
    });

    test('should handle dashboard with all slots filled', () {
      final items = List.generate(
        16,
        (index) => LayoutItem(
          id: 'item$index',
          rect: LayoutRect(
            x: (index % 4),
            y: (index ~/ 4),
            size: LayoutSize(width: 1, height: 1),
          ),
        ),
      );

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 3,
      );

      final result = positioner.position(
        'item16',
        LayoutSize(width: 1, height: 1),
      );

      expect(result.length, 17);
      final newItem = result.last;
      expect(newItem.rect.y, 4); // Should create new row
    });

    test('should handle very large items relative to grid', () {
      final positioner = DashboardAggressivePositioner(
        items: [],
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'large',
        LayoutSize(width: 4, height: 3),
      );

      expect(result.length, 1);
      expect(result[0].rect.size.width, 4);
      expect(result[0].rect.size.height, 3);
    });

    test('should handle mixed size items efficiently', () {
      final items = [
        LayoutItem(
          id: 'small1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 1, height: 1)),
        ),
        LayoutItem(
          id: 'large',
          rect: LayoutRect(x: 1, y: 0, size: LayoutSize(width: 3, height: 2)),
        ),
        LayoutItem(
          id: 'small2',
          rect: LayoutRect(x: 0, y: 1, size: LayoutSize(width: 1, height: 1)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'medium',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 4);
      final medium = result.firstWhere((item) => item.id == 'medium');
      expect(medium.rect.y, 2); // Should find first available spot
    });
  });

  group('Extended Edge Cases', () {
    test('should handle L-shaped gaps', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 3, height: 1)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 0, y: 1, size: LayoutSize(width: 1, height: 2)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item3',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 3);
      final item3 = result.firstWhere((item) => item.id == 'item3');
      expect(item3.rect.x, 1);
      expect(item3.rect.y, 1);
    });

    test('should handle checkerboard pattern', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 1, height: 1)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 2, y: 0, size: LayoutSize(width: 1, height: 1)),
        ),
        LayoutItem(
          id: 'item3',
          rect: LayoutRect(x: 1, y: 1, size: LayoutSize(width: 1, height: 1)),
        ),
        LayoutItem(
          id: 'item4',
          rect: LayoutRect(x: 3, y: 1, size: LayoutSize(width: 1, height: 1)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item5',
        LayoutSize(width: 1, height: 1),
      );

      expect(result.length, 5);
      final item5 = result.firstWhere((item) => item.id == 'item5');
      expect(item5.rect.x, 1);
      expect(item5.rect.y, 0);
    });

    test('should handle staircase pattern', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 1, height: 1)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 1, y: 1, size: LayoutSize(width: 1, height: 1)),
        ),
        LayoutItem(
          id: 'item3',
          rect: LayoutRect(x: 2, y: 2, size: LayoutSize(width: 1, height: 1)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item4',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 4);
      final item4 = result.firstWhere((item) => item.id == 'item4');
      expect(item4.rect.x, 1);
      expect(item4.rect.y, 0);
    });

    test('should handle items spanning multiple cross slots', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 3)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 1, height: 1),
      );

      expect(result.length, 2);
      final item2 = result.firstWhere((item) => item.id == 'item2');
      expect(item2.rect.x, 2);
      expect(item2.rect.y, 0);
    });

    test('should handle after positioning with complex chain', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 1, height: 1)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 1, y: 0, size: LayoutSize(width: 1, height: 1)),
        ),
        LayoutItem(
          id: 'item3',
          rect: LayoutRect(x: 2, y: 0, size: LayoutSize(width: 1, height: 1)),
        ),
        LayoutItem(
          id: 'item4',
          rect: LayoutRect(x: 3, y: 0, size: LayoutSize(width: 1, height: 1)),
        ),
      ];

      final positioner = DashboardAfterPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
        afterId: 'item2',
      );

      final result = positioner.position(
        'item5',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 5);
      final item5Index = result.indexWhere((item) => item.id == 'item5');
      final item2Index = result.indexWhere((item) => item.id == 'item2');
      expect(item5Index, greaterThan(item2Index));

      expect(result[2].id, 'item5');
      expect(result[2].rect.x, 2);
      expect(result[2].rect.y, 0);

      expect(result[3].id, 'item3');
      expect(result[3].rect.x, 0);
      expect(result[3].rect.y, 1);

      expect(result[4].id, 'item4');
      expect(result[4].rect.x, 1);
      expect(result[4].rect.y, 1);
    });

    test('should handle vertical layout with tall items', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 1, height: 3)),
        ),
      ];

      final positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.vertical,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 1, height: 1),
      );

      expect(result.length, 2);
      final item2 = result.firstWhere((item) => item.id == 'item2');
      expect(item2.rect.y, 3);
    });

    test('should handle append with items of varying heights', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 2)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 2, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardAppendPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item3',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 3);
      final item3 = result.firstWhere((item) => item.id == 'item3');
      expect(item3.rect.y, 1);
    });

    test('should handle head insertion with full first row', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 4, height: 1)),
        ),
        LayoutItem(
          id: 'item2',
          rect: LayoutRect(x: 0, y: 1, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardHeadPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );

      final result = positioner.position(
        'item3',
        LayoutSize(width: 2, height: 1),
      );

      expect(result.length, 3);
      expect(result[0].id, 'item3');
      expect(result[0].rect.x, 0);
      expect(result[0].rect.y, 0);
    });

    test('should handle multiple items with same ID check', () {
      final items = [
        LayoutItem(
          id: 'item1',
          rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 2, height: 1)),
        ),
      ];

      final positioner = DashboardAfterPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
        afterId: 'item1',
      );

      final result = positioner.position(
        'item2',
        LayoutSize(width: 2, height: 1),
      );

      // Ensure no duplicate IDs
      final ids = result.map((item) => item.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });
  });

  group('Integration Tests', () {
    test('should handle sequence of additions with different strategies', () {
      var items = <LayoutItem>[];

      // Add first item aggressively
      var positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );
      items = positioner.position('item1', LayoutSize(width: 2, height: 1));

      // Append second item
      positioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
      );
      items = positioner.position('item2', LayoutSize(width: 2, height: 1));

      // Add third item after first
      final afterPositioner = DashboardAfterPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 4,
        maxCrossSlots: 4,
        afterId: 'item1',
      );
      items = afterPositioner.position(
        'item3',
        LayoutSize(width: 2, height: 1),
      );

      expect(items.length, 3);
      final ids = items.map((item) => item.id).toList();
      expect(ids, containsAll(['item1', 'item2', 'item3']));
    });

    test('should maintain layout integrity across multiple operations', () {
      var items = <LayoutItem>[];

      for (int i = 0; i < 5; i++) {
        final positioner = DashboardAppendPositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 4,
          maxCrossSlots: 10,
        );
        items = positioner.position('item$i', LayoutSize(width: 2, height: 1));
      }

      expect(items.length, 5);

      // Verify no overlaps
      for (int i = 0; i < items.length; i++) {
        for (int j = i + 1; j < items.length; j++) {
          expect(
            items[i].rect.hasConflicts(items[j].rect),
            isFalse,
            reason: 'Item ${items[i].id} overlaps with ${items[j].id}',
          );
        }
      }
    });

    test('should handle complex scenario with all positioner types', () {
      var items = <LayoutItem>[];

      // Start with aggressive
      var aggPositioner = DashboardAggressivePositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 6,
        maxCrossSlots: 6,
      );
      items = aggPositioner.position('item1', LayoutSize(width: 3, height: 2));

      // Append items
      var appendPositioner = DashboardAppendPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 6,
        maxCrossSlots: 6,
      );
      items = appendPositioner.position(
        'item2',
        LayoutSize(width: 2, height: 1),
      );

      appendPositioner = DashboardAppendPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 6,
        maxCrossSlots: 6,
      );
      items = appendPositioner.position(
        'item3',
        LayoutSize(width: 2, height: 1),
      );

      // Insert at head
      var headPositioner = DashboardHeadPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 6,
        maxCrossSlots: 6,
      );
      items = headPositioner.position('item0', LayoutSize(width: 1, height: 1));

      // Insert after specific item
      var afterPositioner = DashboardAfterPositioner(
        items: items,
        axis: DashboardAxis.horizontal,
        mainAxisSlots: 6,
        maxCrossSlots: 6,
        afterId: 'item1',
      );
      items = afterPositioner.position(
        'item1.5',
        LayoutSize(width: 1, height: 1),
      );

      expect(items.length, 5);

      // Verify no overlaps
      for (int i = 0; i < items.length; i++) {
        for (int j = i + 1; j < items.length; j++) {
          expect(
            items[i].rect.hasConflicts(items[j].rect),
            isFalse,
            reason: 'Item ${items[i].id} overlaps with ${items[j].id}',
          );
        }
      }
    });
  });
}
