import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

void main() async {
  group('Benchmark Tests', () {
    test('benchmark: aggressive positioning with 50 items', () {
      final stopwatch = Stopwatch()..start();

      var items = <LayoutItem>[];
      for (int i = 0; i < 50; i++) {
        final positioner = DashboardAggressivePositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 12,
          maxCrossSlots: 20,
        );
        items = positioner.position(
          'item$i',
          LayoutSize(
            width: 1 + (i % 3),
            height: 1 + (i % 2),
          ),
        );
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      debugPrint('Aggressive positioning 50 items: ${duration}ms');
      expect(items.length, 50);
      expect(duration, lessThan(5000)); // Should complete in < 5 seconds

      expect(
        () => LayoutChecker.assertNoOverflow(
          items,
          DashboardAxis.horizontal,
          12,
        ),
        returnsNormally,
      );

      expect(
        () => LayoutChecker.assertNoConflicts(items),
        returnsNormally,
      );
    });

    test('benchmark: append positioning with 50 items', () {
      final stopwatch = Stopwatch()..start();

      var items = <LayoutItem>[];
      for (int i = 0; i < 50; i++) {
        final positioner = DashboardAppendPositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 12,
          maxCrossSlots: 20,
        );
        items = positioner.position('item$i', LayoutSize(width: 2, height: 1));
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      debugPrint('Append positioning 50 items: ${duration}ms');
      expect(items.length, 50);
      expect(duration, lessThan(5000));

      expect(
        () => LayoutChecker.assertNoOverflow(
          items,
          DashboardAxis.horizontal,
          12,
        ),
        returnsNormally,
      );

      expect(
        () => LayoutChecker.assertNoConflicts(items),
        returnsNormally,
      );
    });

    test('benchmark: after positioning with 30 items', () {
      final stopwatch = Stopwatch()..start();

      var items = <LayoutItem>[];

      // Create initial layout
      for (int i = 0; i < 10; i++) {
        final positioner = DashboardAppendPositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 12,
          maxCrossSlots: 20,
        );
        items = positioner.position('item$i', LayoutSize(width: 2, height: 1));
      }

      // Insert items after various positions
      for (int i = 10; i < 30; i++) {
        final afterId = 'item${(i - 10) % 10}';
        final positioner = DashboardAfterPositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 12,
          maxCrossSlots: 20,
          afterId: afterId,
        );
        items = positioner.position('item$i', LayoutSize(width: 1, height: 1));
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      debugPrint('After positioning 30 items: ${duration}ms');
      expect(items.length, 30);
      expect(duration, lessThan(10000)); // More complex, allow 10 seconds

      expect(
        () => LayoutChecker.assertNoOverflow(
          items,
          DashboardAxis.horizontal,
          12,
        ),
        returnsNormally,
      );

      expect(
        () => LayoutChecker.assertNoConflicts(items),
        returnsNormally,
      );
    });

    test('benchmark: large dashboard with 100 items', () {
      final stopwatch = Stopwatch()..start();

      var items = <LayoutItem>[];
      for (int i = 0; i < 100; i++) {
        final positioner = DashboardAggressivePositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 20,
          maxCrossSlots: 30,
        );

        final width = 1 + (i % 4);
        final height = 1 + (i % 3);

        items = positioner.position(
          'item$i',
          LayoutSize(
            width: width,
            height: height,
          ),
        );
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      debugPrint('Large dashboard 100 items: ${duration}ms');
      expect(items.length, 100);
      expect(duration, lessThan(15000)); // Allow 15 seconds for 100 items

      expect(
        () => LayoutChecker.assertNoOverflow(
          items,
          DashboardAxis.horizontal,
          20,
        ),
        returnsNormally,
      );

      expect(
        () => LayoutChecker.assertNoConflicts(items),
        returnsNormally,
      );
    });

    test('benchmark: mixed operations on medium dashboard', () {
      final stopwatch = Stopwatch()..start();

      var items = <LayoutItem>[];

      // Create base layout (30 items)
      for (int i = 0; i < 30; i++) {
        final positioner = DashboardAppendPositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 12,
          maxCrossSlots: 20,
        );
        items = positioner.position('item$i', LayoutSize(width: 2, height: 1));
      }

      // Perform 20 mixed operations
      for (int i = 0; i < 20; i++) {
        if (i % 3 == 0) {
          // Head insertion
          final positioner = DashboardHeadPositioner(
            items: items,
            axis: DashboardAxis.horizontal,
            mainAxisSlots: 12,
            maxCrossSlots: 20,
          );
          items = positioner.position(
            'head$i',
            LayoutSize(width: 1, height: 1),
          );
        } else if (i % 3 == 1) {
          // After insertion
          final afterId = 'item${i % 30}';
          final positioner = DashboardAfterPositioner(
            items: items,
            axis: DashboardAxis.horizontal,
            mainAxisSlots: 12,
            maxCrossSlots: 20,
            afterId: afterId,
          );
          items = positioner.position(
            'after$i',
            LayoutSize(width: 1, height: 1),
          );
        } else {
          // Aggressive positioning
          final positioner = DashboardAggressivePositioner(
            items: items,
            axis: DashboardAxis.horizontal,
            mainAxisSlots: 12,
            maxCrossSlots: 20,
          );
          items = positioner.position('agg$i', LayoutSize(width: 2, height: 1));
        }
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      debugPrint('Mixed operations (50 total items): ${duration}ms');
      expect(items.length, 50);
      expect(duration, lessThan(12000));

      expect(
        () => LayoutChecker.assertNoOverflow(
          items,
          DashboardAxis.horizontal,
          12,
        ),
        returnsNormally,
      );

      expect(
        () => LayoutChecker.assertNoConflicts(items),
        returnsNormally,
      );
    });

    test('benchmark: worst case scenario - maximum fragmentation', () {
      final stopwatch = Stopwatch()..start();

      var items = <LayoutItem>[];

      // Create checkerboard pattern (fragmented layout)
      for (int row = 0; row < 10; row++) {
        for (int col = 0; col < 10; col++) {
          if ((row + col) % 2 == 0) {
            items.add(
              LayoutItem(
                id: 'checkerboard_${row}_$col',
                rect: LayoutRect(
                  x: col,
                  y: row,
                  size: LayoutSize(width: 1, height: 1),
                ),
              ),
            );
          }
        }
      }

      // Try to fill gaps with various sizes
      for (int i = 0; i < 20; i++) {
        final positioner = DashboardAggressivePositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 10,
          maxCrossSlots: 15,
        );
        items = positioner.position('fill$i', LayoutSize(width: 1, height: 1));
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      debugPrint('Worst case fragmentation: ${duration}ms');
      expect(
        duration,
        lessThan(8000),
      ); // More complex, but should still be reasonable

      expect(
        () => LayoutChecker.assertNoOverflow(
          items,
          DashboardAxis.horizontal,
          10,
        ),
        returnsNormally,
      );

      expect(
        () => LayoutChecker.assertNoConflicts(items),
        returnsNormally,
      );
    });

    test('benchmark: vertical layout with 50 items', () {
      final stopwatch = Stopwatch()..start();

      var items = <LayoutItem>[];
      for (int i = 0; i < 50; i++) {
        final positioner = DashboardAggressivePositioner(
          items: items,
          axis: DashboardAxis.vertical,
          mainAxisSlots: 12,
          maxCrossSlots: 20,
        );
        items = positioner.position(
          'item$i',
          LayoutSize(
            width: 1 + (i % 2),
            height: 1 + (i % 3),
          ),
        );
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      debugPrint('Vertical layout 50 items: ${duration}ms');
      expect(items.length, 50);
      expect(duration, lessThan(5000));

      expect(
        () => LayoutChecker.assertNoOverflow(
          items,
          DashboardAxis.vertical,
          12,
        ),
        returnsNormally,
      );

      expect(
        () => LayoutChecker.assertNoConflicts(items),
        returnsNormally,
      );
    });

    test('benchmark: memory usage - large item count', () {
      final stopwatch = Stopwatch()..start();

      var items = <LayoutItem>[];

      // Create 200 items to test memory efficiency
      for (int i = 0; i < 200; i++) {
        final positioner = DashboardAggressivePositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 20,
          maxCrossSlots: 40,
        );
        items = positioner.position('item$i', LayoutSize(width: 1, height: 1));
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      debugPrint('Memory usage benchmark (200 items): ${duration}ms');

      expect(items.length, 200);

      // Verify data structure integrity
      final ids = items.map((item) => item.id).toSet();
      expect(ids.length, 200); // All unique IDs

      expect(
        () => LayoutChecker.assertNoOverflow(
          items,
          DashboardAxis.horizontal,
          20,
        ),
        returnsNormally,
      );

      expect(
        () => LayoutChecker.assertNoConflicts(items),
        returnsNormally,
      );
    });
  });

  group('Performance Edge Cases', () {
    test('should handle rapid successive positioning operations', () {
      var items = <LayoutItem>[];

      // Simulate rapid UI updates
      for (int batch = 0; batch < 5; batch++) {
        for (int i = 0; i < 10; i++) {
          final idx = batch * 10 + i;
          final positioner = DashboardAggressivePositioner(
            items: items,
            axis: DashboardAxis.horizontal,
            mainAxisSlots: 12,
            maxCrossSlots: 20,
          );
          items = positioner.position(
            'item$idx',
            LayoutSize(width: 2, height: 1),
          );
        }
      }

      expect(items.length, 50);

      expect(
        () => LayoutChecker.assertNoOverflow(
          items,
          DashboardAxis.horizontal,
          12,
        ),
        returnsNormally,
      );

      expect(
        () => LayoutChecker.assertNoConflicts(items),
        returnsNormally,
      );
    });

    test('should maintain performance with very wide grid', () {
      final stopwatch = Stopwatch()..start();

      var items = <LayoutItem>[];
      for (int i = 0; i < 30; i++) {
        final positioner = DashboardAggressivePositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 50, // Very wide
          maxCrossSlots: 10,
        );
        items = positioner.position('item$i', LayoutSize(width: 3, height: 1));
      }

      stopwatch.stop();

      debugPrint('Wide grid (50 slots): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));

      expect(
        () => LayoutChecker.assertNoOverflow(
          items,
          DashboardAxis.horizontal,
          50,
        ),
        returnsNormally,
      );

      expect(
        () => LayoutChecker.assertNoConflicts(items),
        returnsNormally,
      );
    });

    test('should maintain performance with very tall grid', () {
      final stopwatch = Stopwatch()..start();

      var items = <LayoutItem>[];
      for (int i = 0; i < 30; i++) {
        final positioner = DashboardAggressivePositioner(
          items: items,
          axis: DashboardAxis.horizontal,
          mainAxisSlots: 10,
          maxCrossSlots: 50, // Very tall
        );
        items = positioner.position('item$i', LayoutSize(width: 2, height: 1));
      }

      stopwatch.stop();

      debugPrint(
        'Tall grid (50 cross slots): ${stopwatch.elapsedMilliseconds}ms',
      );
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));

      expect(
        () => LayoutChecker.assertNoOverflow(
          items,
          DashboardAxis.horizontal,
          10,
        ),
        returnsNormally,
      );

      expect(
        () => LayoutChecker.assertNoConflicts(items),
        returnsNormally,
      );
    });
  });
}
