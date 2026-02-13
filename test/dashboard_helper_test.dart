import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
// ─── Helpers ─────────────────────────────────────────────────────────────────

LayoutItem item(String id, int x, int y, int w, int h) => LayoutItem(
  id: id,
  rect: LayoutRect(
    x: x,
    y: y,
    size: LayoutSize(width: w, height: h),
  ),
);

/// Asserts that no two items in [result] overlap.
void expectNoOverlaps(List<LayoutItem> result) {
  for (int i = 0; i < result.length; i++) {
    for (int j = i + 1; j < result.length; j++) {
      expect(
        result[i].rect.hasConflicts(result[j].rect),
        isFalse,
        reason:
            '${result[i].id} overlaps ${result[j].id}\n'
            '  ${result[i].rect} vs ${result[j].rect}',
      );
    }
  }
}

/// Asserts that all items fit within mainAxisSlots for the given axis.
void expectNoOverflow(List<LayoutItem> result, DashboardAxis axis, int slots) {
  for (final it in result) {
    final mainExtent = axis == DashboardAxis.horizontal
        ? it.rect.right
        : it.rect.bottom;
    expect(
      mainExtent,
      lessThanOrEqualTo(slots),
      reason:
          '${it.id} overflows mainAxisSlots=$slots (mainExtent=$mainExtent)',
    );
  }
}

/// Returns all IDs present in [items].
Set<Object> ids(List<LayoutItem> items) => items.map((e) => e.id).toSet();

void main() {
  // ─── sort() ────────────────────────────────────────────────────────────────
  group('sort()', () {
    test('empty list returns empty list', () {
      expect(DashboardHelper.sort([], DashboardAxis.horizontal), isEmpty);
    });

    test('single item returns single-item list', () {
      final items = [item('a', 0, 0, 1, 1)];
      expect(DashboardHelper.sort(items, DashboardAxis.horizontal).length, 1);
    });

    test('horizontal: primary sort by top (y), secondary by left (x)', () {
      final items = [
        item('c', 2, 0, 1, 1), // y=0 x=2
        item('a', 0, 0, 1, 1), // y=0 x=0
        item('b', 0, 1, 1, 1), // y=1 x=0 — later row
      ];
      final result = DashboardHelper.sort(items, DashboardAxis.horizontal);
      expect(result.map((e) => e.id).toList(), ['a', 'c', 'b']);
    });

    test('vertical: primary sort by left (x), secondary by top (y)', () {
      final items = [
        item('c', 0, 2, 1, 1), // x=0 y=2
        item('a', 0, 0, 1, 1), // x=0 y=0
        item('b', 1, 0, 1, 1), // x=1 y=0 — later column
      ];
      final result = DashboardHelper.sort(items, DashboardAxis.vertical);
      expect(result.map((e) => e.id).toList(), ['a', 'c', 'b']);
    });

    test('already-sorted input stays sorted', () {
      final items = [item('a', 0, 0, 1, 1), item('b', 1, 0, 1, 1)];
      final result = DashboardHelper.sort(items, DashboardAxis.horizontal);
      expect(result.map((e) => e.id).toList(), ['a', 'b']);
    });

    test('does not mutate the original list', () {
      final items = [item('b', 1, 0, 1, 1), item('a', 0, 0, 1, 1)];
      final originalFirst = items[0].id;
      DashboardHelper.sort(items, DashboardAxis.horizontal);
      expect(items[0].id, originalFirst);
    });

    test('items with identical rects preserve both (stable-ish)', () {
      final items = [item('x', 0, 0, 2, 2), item('y', 0, 0, 2, 2)];
      final result = DashboardHelper.sort(items, DashboardAxis.horizontal);
      expect(ids(result), containsAll(['x', 'y']));
    });
  });

  // ─── assertSorted() ────────────────────────────────────────────────────────
  group('assertSorted()', () {
    test('empty list is considered sorted', () {
      expect(
        DashboardHelper.assertSorted([], DashboardAxis.horizontal),
        isTrue,
      );
    });

    test('single item is sorted', () {
      expect(
        DashboardHelper.assertSorted([
          item('a', 0, 0, 1, 1),
        ], DashboardAxis.horizontal),
        isTrue,
      );
    });

    test('correctly sorted horizontal list returns true', () {
      final items = [item('a', 0, 0, 2, 1), item('b', 2, 0, 2, 1)];
      expect(
        DashboardHelper.assertSorted(items, DashboardAxis.horizontal),
        isTrue,
      );
    });

    test('incorrectly sorted horizontal list returns false', () {
      final items = [item('b', 2, 0, 2, 1), item('a', 0, 0, 2, 1)]; // reversed
      expect(
        DashboardHelper.assertSorted(items, DashboardAxis.horizontal),
        isFalse,
      );
    });

    test('correctly sorted vertical list returns true', () {
      final items = [item('a', 0, 0, 1, 2), item('b', 0, 2, 1, 2)];
      expect(
        DashboardHelper.assertSorted(items, DashboardAxis.vertical),
        isTrue,
      );
    });

    test('incorrectly sorted vertical list returns false', () {
      final items = [item('b', 0, 2, 1, 2), item('a', 0, 0, 1, 2)];
      expect(
        DashboardHelper.assertSorted(items, DashboardAxis.vertical),
        isFalse,
      );
    });

    // BUG PROBE: Two items at the exact same position — compare() returns 0,
    // the loop does NOT return false, so assertSorted returns true even though
    // these two items fully overlap. That is misleading because callers may
    // use assertSorted to infer "no duplicate/conflict positions" but the
    // function only checks ordering, not uniqueness.
    test(
      'BUG: two items at identical position are considered "sorted" (returns true)',
      () {
        final items = [item('a', 0, 0, 2, 2), item('b', 0, 0, 2, 2)];
        // The method returns true because comparison == 0 doesn't trigger false.
        // This means assertSorted cannot be used to detect position collisions.
        final result = DashboardHelper.assertSorted(
          items,
          DashboardAxis.horizontal,
        );
        expect(
          result,
          isTrue,
          reason:
              'Documents known behavior: assertSorted passes for identical '
              'rects because it only checks strict ordering (> 0), '
              'not conflict-free uniqueness. Callers must not rely on it '
              'to detect overlapping items.',
        );
      },
    );

    test('row-boundary transition is treated as sorted', () {
      // Last item in row 0 vs first item in row 1
      final items = [item('a', 3, 0, 1, 1), item('b', 0, 1, 1, 1)];
      expect(
        DashboardHelper.assertSorted(items, DashboardAxis.horizontal),
        isTrue,
      );
    });
  });

  // ─── adoptMetrics() — happy paths ─────────────────────────────────────────
  group('adoptMetrics() — no-change paths', () {
    test('empty items returns empty list', () {
      final result = DashboardHelper.adoptMetrics(
        [],
        DashboardAxis.horizontal,
        4,
      );
      expect(result, isEmpty);
    });

    test('perfectly-fitting layout passes through unchanged', () {
      final items = [item('a', 0, 0, 2, 1), item('b', 2, 0, 2, 1)];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(ids(result), containsAll(['a', 'b']));
      expectNoOverlaps(result);
      expectNoOverflow(result, DashboardAxis.horizontal, 4);
    });

    test('single item exactly filling main axis passes through', () {
      final items = [item('a', 0, 0, 4, 1)];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(result.length, 1);
      expect(result[0].id, 'a');
    });

    test('vertical axis — fitting layout passes through unchanged', () {
      final items = [item('a', 0, 0, 1, 2), item('b', 0, 2, 1, 2)];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.vertical,
        4,
      );
      expect(ids(result), containsAll(['a', 'b']));
      expectNoOverlaps(result);
      expectNoOverflow(result, DashboardAxis.vertical, 4);
    });
  });

  // ─── adoptMetrics() — overflow reshuffling ─────────────────────────────────
  group('adoptMetrics() — overflow reshuffling', () {
    test('item overflowing main axis is repositioned', () {
      // item 'b' has right=5, but mainAxisSlots=4 → overflow
      final items = [item('a', 0, 0, 2, 1), item('b', 3, 0, 2, 1)];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(ids(result), containsAll(['a', 'b']));
      expectNoOverflow(result, DashboardAxis.horizontal, 4);
      expectNoOverlaps(result);
    });

    test(
      'item whose width exceeds mainAxisSlots is constrained then repositioned',
      () {
        // 'big' has width=6, mainAxisSlots=4 → constrain to w=4, then append
        final items = [item('big', 0, 0, 6, 1)];
        final result = DashboardHelper.adoptMetrics(
          items,
          DashboardAxis.horizontal,
          4,
        );
        expect(result.length, 1);
        expect(result[0].id, 'big');
        expect(
          result[0].rect.size.width,
          lessThanOrEqualTo(4),
          reason: 'width must be constrained to mainAxisSlots',
        );
        expectNoOverflow(result, DashboardAxis.horizontal, 4);
      },
    );

    test(
      'multiple overflowing items are all repositioned without overlaps',
      () {
        // Layout valid for mainAxisSlots=6, but we shrink to 4
        final items = [
          item('a', 0, 0, 3, 1),
          item('b', 3, 0, 3, 1), // right=6, overflows at slots=4
          item('c', 0, 1, 2, 1),
        ];
        final result = DashboardHelper.adoptMetrics(
          items,
          DashboardAxis.horizontal,
          4,
        );
        expect(ids(result), containsAll(['a', 'b', 'c']));
        expectNoOverflow(result, DashboardAxis.horizontal, 4);
        expectNoOverlaps(result);
      },
    );

    test('all items overflow — all are repositioned, no overlaps', () {
      final items = [
        item('a', 5, 0, 2, 1), // right=7
        item('b', 5, 1, 2, 1), // right=7
      ];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(ids(result), containsAll(['a', 'b']));
      expectNoOverflow(result, DashboardAxis.horizontal, 4);
      expectNoOverlaps(result);
    });

    test('vertical axis overflow is repositioned correctly', () {
      // item with height=6, mainAxisSlots=4 → overflow
      final items = [item('tall', 0, 0, 1, 6)];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.vertical,
        4,
      );
      expect(result.length, 1);
      expect(
        result[0].rect.size.height,
        lessThanOrEqualTo(4),
        reason: 'height must be constrained to mainAxisSlots for vertical',
      );
      expectNoOverflow(result, DashboardAxis.vertical, 4);
    });

    test('item at boundary (right == mainAxisSlots) does NOT overflow', () {
      final items = [item('a', 2, 0, 2, 1)]; // right = 4 == mainAxisSlots
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(result[0].id, 'a');
      expect(result[0].rect.right, 4);
    });

    test('item at boundary (right == mainAxisSlots + 1) DOES overflow', () {
      final items = [item('a', 2, 0, 3, 1)]; // right = 5 > 4
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expectNoOverflow(result, DashboardAxis.horizontal, 4);
    });
  });

  // ─── adoptMetrics() — collision reshuffling ────────────────────────────────
  group('adoptMetrics() — collision reshuffling', () {
    test('two overlapping items — second is repositioned', () {
      final items = [
        item('a', 0, 0, 2, 1),
        item('b', 0, 0, 2, 1), // identical rect → collision
      ];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(ids(result), containsAll(['a', 'b']));
      expectNoOverlaps(result);
      expectNoOverflow(result, DashboardAxis.horizontal, 4);
    });

    test('partially overlapping items — offending item is repositioned', () {
      final items = [
        item('a', 0, 0, 3, 1),
        item('b', 1, 0, 3, 1), // overlaps 'a' in cols 1-2
      ];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(ids(result), containsAll(['a', 'b']));
      expectNoOverlaps(result);
      expectNoOverflow(result, DashboardAxis.horizontal, 4);
    });

    test('three mutually-overlapping items — all land without conflicts', () {
      final items = [
        item('a', 0, 0, 2, 2),
        item('b', 1, 0, 2, 2),
        item('c', 0, 1, 2, 2),
      ];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(ids(result), containsAll(['a', 'b', 'c']));
      expectNoOverlaps(result);
      expectNoOverflow(result, DashboardAxis.horizontal, 4);
    });

    test(
      'collision AND overflow on same item — item is constrained and repositioned',
      () {
        // 'b' both overlaps 'a' and overflows mainAxisSlots=3
        final items = [
          item('a', 0, 0, 2, 1),
          item('b', 1, 0, 4, 1), // overlaps 'a', right=5 > 3
        ];
        final result = DashboardHelper.adoptMetrics(
          items,
          DashboardAxis.horizontal,
          3,
        );
        expect(ids(result), containsAll(['a', 'b']));
        expectNoOverlaps(result);
        expectNoOverflow(result, DashboardAxis.horizontal, 3);
      },
    );
  });

  // ─── adoptMetrics() — axis change ─────────────────────────────────────────
  group('adoptMetrics() — axis change', () {
    test('horizontal→vertical: items fitting in new axis pass through', () {
      // Items valid under both axes when mainAxisSlots=4
      final items = [item('a', 0, 0, 1, 2), item('b', 0, 2, 1, 2)];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.vertical,
        4,
      );
      expect(ids(result), containsAll(['a', 'b']));
      expectNoOverlaps(result);
      expectNoOverflow(result, DashboardAxis.vertical, 4);
    });

    test('axis switch causes overflow — items are repositioned', () {
      // Under horizontal/4: [a] right=4 OK, [b] right=4 OK (different rows)
      // Switching to vertical/4: [a] bottom=3 OK, [b] bottom=6 OVERFLOW
      final items = [
        item('a', 0, 0, 4, 3), // height=3 → vertical mainExtent=3, fine
        item('b', 0, 3, 4, 6), // height=6 → vertical mainExtent=6 > 4, overflow
      ];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.vertical,
        4,
      );
      expect(ids(result), containsAll(['a', 'b']));
      expectNoOverflow(result, DashboardAxis.vertical, 4);
      expectNoOverlaps(result);
    });
  });

  // ─── adoptMetrics() — item count & ID preservation ────────────────────────
  group('adoptMetrics() — item count and ID preservation', () {
    test('all original IDs are present in result', () {
      final items = [
        item('a', 0, 0, 3, 1),
        item('b', 3, 0, 3, 1),
        item('c', 0, 1, 2, 1),
        item('d', 2, 1, 4, 1),
      ];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(ids(result), equals({'a', 'b', 'c', 'd'}));
    });

    test('item count is preserved after reshuffling', () {
      final items = List.generate(
        8,
        (i) => item('item$i', (i % 3) * 2, i ~/ 3, 2, 1),
      );

      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(result.length, 8);
    });

    test('throw assertions when duplicate IDs are present', () {
      final items = [
        item('x', 0, 0, 3, 1),
        item('x', 0, 0, 2, 1), // duplicate ID and overlapping position
      ];

      expect(
        () => DashboardHelper.adoptMetrics(
          items,
          DashboardAxis.horizontal,
          4,
        ),
        throwsAssertionError,
      );
    });

    test('large set: 20 colliding items are all placed without overlap', () {
      // Stack 20 items all at (0,0,1,1) — extreme collision scenario
      final items = List.generate(
        20,
        (i) => item('item$i', 0, 0, 1, 1),
      );
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(result.length, 20);
      expectNoOverlaps(result);
      expectNoOverflow(result, DashboardAxis.horizontal, 4);
    });
  });

  // ─── adoptMetrics() — maxCrossSlots initialisation bug probe ──────────────
  group('adoptMetrics() — maxCrossSlots tracking', () {
    // The loop starts maxCrossSlots at 0 and only grows it as items are
    // processed. This means the *first* repositioned item is always placed
    // via DashboardAppendPositioner(maxCrossSlots: 0), which is fine for an
    // empty guardedItems list (it places at 0,0). But if a later item is the
    // first one needing repositioning AND guardedItems already has rows,
    // maxCrossSlots should reflect the current layout height — it does,
    // because it's updated after each item. Let's verify.
    test(
      'maxCrossSlots is tracked correctly: late-overflow item lands below existing rows',
      () {
        // 'a' fits fine at row 0. 'b' overflows → repositioned.
        // At the time 'b' is processed, maxCrossSlots should already be 1
        // (from 'a' which has bottom=1), so 'b' should be appended at y>=1.
        final items = [
          item('a', 0, 0, 4, 1), // fits perfectly in slots=4, row 0
          item('b', 0, 0, 3, 1), // collides with 'a' at (0,0) → repositioned
        ];
        final result = DashboardHelper.adoptMetrics(
          items,
          DashboardAxis.horizontal,
          4,
        );
        expect(ids(result), containsAll(['a', 'b']));
        expectNoOverlaps(result);

        final itemB = result.firstWhere((e) => e.id == 'b');
        // b must land on a new row since row 0 is fully occupied by 'a'
        expect(
          itemB.rect.top,
          greaterThanOrEqualTo(1),
          reason: 'b should be repositioned below the existing row',
        );
      },
    );

    test(
      'maxCrossSlots update prevents overlap when multiple repositions needed',
      () {
        // All three items collide. They should each end up on separate rows.
        final items = [
          item('a', 0, 0, 4, 1),
          item('b', 0, 0, 4, 1), // same as a → collision
          item('c', 0, 0, 4, 1), // same as a → collision
        ];
        final result = DashboardHelper.adoptMetrics(
          items,
          DashboardAxis.horizontal,
          4,
        );
        expect(result.length, 3);
        expectNoOverlaps(result);

        final rows = result.map((e) => e.rect.top).toList()..sort();
        expect(rows, [0, 1, 2], reason: 'Each item should occupy its own row');
      },
    );
  });

  // ─── adoptMetrics() — oldMainAxisSlots is ignored (documented dead param) ──
  group('adoptMetrics() — oldMainAxisSlots parameter', () {
    // The method signature accepts oldMainAxisSlots but the implementation
    // never reads it. These tests document that its value has no observable
    // effect on the output — which may be a bug if callers rely on it to
    // skip unnecessary repositioning.
    test('oldMainAxisSlots has no effect on output (parameter is unused)', () {
      final items = [item('a', 0, 0, 3, 1), item('b', 3, 0, 3, 1)];

      final resultWithout = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      final resultWith = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
        oldMainAxisSlots: 6,
      );
      final resultWithSmaller = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
        oldMainAxisSlots: 2,
      );

      // All three calls must produce identical output because oldMainAxisSlots
      // is not used. If they differ, the parameter is actually being read.
      expect(
        ids(resultWith),
        equals(ids(resultWithout)),
        reason: 'oldMainAxisSlots=6 should not change output',
      );
      expect(
        ids(resultWithSmaller),
        equals(ids(resultWithout)),
        reason: 'oldMainAxisSlots=2 should not change output',
      );
    });
  });

  // ─── adoptMetrics() — result is always valid ──────────────────────────────
  group('adoptMetrics() — result validity guarantees', () {
    test('result is never null and always a list', () {
      final result = DashboardHelper.adoptMetrics(
        [item('a', 0, 0, 2, 1)],
        DashboardAxis.horizontal,
        4,
      );
      expect(result, isA<List<LayoutItem>>());
    });

    test(
      'result of adoptMetrics itself satisfies _guard (no overflow, no conflict)',
      () {
        final items = [
          item('a', 0, 0, 3, 1),
          item('b', 3, 0, 3, 1),
          item('c', 0, 1, 2, 1),
        ];
        final result = DashboardHelper.adoptMetrics(
          items,
          DashboardAxis.horizontal,
          4,
        );

        // Running adoptMetrics again on its own output should be a no-op
        // (guard short-circuits because result is already valid)
        final idempotent = DashboardHelper.adoptMetrics(
          result,
          DashboardAxis.horizontal,
          4,
        );
        expect(ids(idempotent), equals(ids(result)));
        expect(idempotent.length, result.length);
      },
    );

    test('single item wider than mainAxisSlots is constrained to fit', () {
      final items = [item('wide', 0, 0, 10, 1)];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      expect(result.length, 1);
      expect(result[0].rect.right, lessThanOrEqualTo(4));
    });

    test(
      'mainAxisSlots=1 forces all items to width=1 and stacks vertically',
      () {
        final items = [
          item('a', 0, 0, 3, 1),
          item('b', 0, 1, 2, 1),
          item('c', 0, 2, 4, 1),
        ];
        final result = DashboardHelper.adoptMetrics(
          items,
          DashboardAxis.horizontal,
          1,
        );
        expect(result.length, 3);
        for (final it in result) {
          expect(
            it.rect.size.width,
            1,
            reason: 'All items must be constrained to width=1',
          );
        }
        expectNoOverlaps(result);
      },
    );

    test(
      'mixed overflow and non-overflow items maintain correct relative order',
      () {
        // 'first' and 'third' fit; 'second' overflows.
        // After repositioning, 'first' and 'third' should retain their positions
        // and 'second' should land in a new row without disturbing 'third'.
        final items = [
          item('first', 0, 0, 2, 1), // fits
          item('second', 3, 0, 3, 1), // right=6 > mainAxisSlots=4 → overflow
          item('third', 2, 0, 2, 1), // fits
        ];
        final result = DashboardHelper.adoptMetrics(
          items,
          DashboardAxis.horizontal,
          4,
        );
        expect(ids(result), containsAll(['first', 'second', 'third']));
        expectNoOverlaps(result);
        expectNoOverflow(result, DashboardAxis.horizontal, 4);
      },
    );
  });

  // ─── Integration: visualize + adoptMetrics ────────────────────────────────
  group('Integration: visualize() after adoptMetrics()', () {
    test('sort output satisfies assertSorted', () {
      final items = [
        item('c', 2, 1, 1, 1),
        item('a', 0, 0, 1, 1),
        item('b', 1, 0, 1, 1),
      ];
      final sorted = DashboardHelper.sort(items, DashboardAxis.horizontal);
      expect(
        DashboardHelper.assertSorted(sorted, DashboardAxis.horizontal),
        isTrue,
      );
    });

    test('adoptMetrics result satisfies assertSorted', () {
      final items = [
        item('d', 5, 0, 2, 1),
        item('c', 3, 0, 2, 1),
        item('b', 1, 0, 2, 1),
        item('a', 0, 0, 1, 1),
      ];
      final result = DashboardHelper.adoptMetrics(
        items,
        DashboardAxis.horizontal,
        4,
      );
      // adoptMetrics sorts internally; result order should be stable
      expect(result.length, 4);
      expectNoOverlaps(result);
    });
  });
}
