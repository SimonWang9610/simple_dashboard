import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

LayoutItem _item(String id, int x, int y, int w, int h) => LayoutItem(
  id: id,
  rect: LayoutRect(x: x, y: y, size: LayoutSize(width: w, height: h)),
);

void _expectNoOverlaps(List<LayoutItem> items) {
  for (int i = 0; i < items.length; i++) {
    for (int j = i + 1; j < items.length; j++) {
      expect(
        items[i].rect.hasConflicts(items[j].rect),
        isFalse,
        reason: '${items[i].id} overlaps ${items[j].id}',
      );
    }
  }
}

void _expectNoOverflow(
  List<LayoutItem> items,
  DashboardAxis axis,
  int slots,
) {
  for (final item in items) {
    final extent = axis == DashboardAxis.horizontal
        ? item.rect.right
        : item.rect.bottom;
    expect(
      extent,
      lessThanOrEqualTo(slots),
      reason: '${item.id} overflows mainAxisSlots=$slots',
    );
  }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('DashboardController', () {
    // ── factory constructor ────────────────────────────────────────────────

    group('factory constructor', () {
      test('defaults: horizontal axis, empty items, zero maxCrossAxisSlots', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        expect(ctrl.axis, DashboardAxis.horizontal);
        expect(ctrl.mainAxisSlots, 4);
        expect(ctrl.items, isEmpty);
        expect(ctrl.maxCrossAxisSlots, 0);
      });

      test('can specify vertical axis', () {
        final ctrl = DashboardController(
          axis: DashboardAxis.vertical,
          mainAxisSlots: 3,
        );
        expect(ctrl.axis, DashboardAxis.vertical);
        expect(ctrl.mainAxisSlots, 3);
      });

      test('initial items are adopted and stored', () {
        final initial = [
          _item('a', 0, 0, 2, 1),
          _item('b', 2, 0, 2, 1),
        ];
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: initial,
        );
        expect(ctrl.items.length, 2);
        expect(ctrl.items.map((e) => e.id), containsAll(['a', 'b']));
      });

      test('maxCrossAxisSlots computed from initial items (horizontal)', () {
        // For horizontal axis, cross axis slots = item.rect.bottom
        final initial = [
          _item('a', 0, 0, 2, 3), // bottom = 3
          _item('b', 2, 0, 2, 2), // bottom = 2
        ];
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: initial,
        );
        expect(ctrl.maxCrossAxisSlots, 3);
      });

      test('maxCrossAxisSlots computed from initial items (vertical)', () {
        // For vertical axis, cross axis slots = item.rect.right
        final initial = [
          _item('a', 0, 0, 3, 2), // right = 3
          _item('b', 0, 2, 2, 2), // right = 2
        ];
        final ctrl = DashboardController(
          axis: DashboardAxis.vertical,
          mainAxisSlots: 4,
          initialItems: initial,
        );
        expect(ctrl.maxCrossAxisSlots, 3);
      });

      test('null initialItems yields empty items list', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: null,
        );
        expect(ctrl.items, isEmpty);
      });
    });

    // ── items setter ───────────────────────────────────────────────────────

    group('items setter', () {
      test('setting items triggers notifyListeners', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        int count = 0;
        ctrl.addListener(() => count++);

        ctrl.items = [_item('a', 0, 0, 1, 1)];

        expect(count, 1);
      });

      test('items are stored as an unmodifiable list', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        ctrl.items = [_item('a', 0, 0, 1, 1)];
        expect(
          () => ctrl.items.add(_item('b', 1, 0, 1, 1)),
          throwsUnsupportedError,
        );
      });

      test('updating items resets sortedItems cache', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 1, 1)],
        );
        final before = ctrl.sortedItems;
        ctrl.items = [_item('b', 0, 0, 1, 1)];
        final after = ctrl.sortedItems;
        expect(identical(before, after), isFalse);
      });
    });

    // ── add() ──────────────────────────────────────────────────────────────

    group('add() — append strategy', () {
      test('adds a single item when list is empty', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        ctrl.add(
          'a',
          const LayoutSize(width: 2, height: 1),
          strategy: PositionStrategy.append,
        );
        expect(ctrl.items.length, 1);
        expect(ctrl.items.first.id, 'a');
      });

      test('second item is appended after first', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        ctrl.add('a', const LayoutSize(width: 2, height: 1),
            strategy: PositionStrategy.append);
        ctrl.add('b', const LayoutSize(width: 2, height: 1),
            strategy: PositionStrategy.append);
        expect(ctrl.items.length, 2);
        expect(ctrl.items.any((i) => i.id == 'b'), isTrue);
        _expectNoOverlaps(ctrl.items.toList());
      });

      test('add() notifies listeners', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        int count = 0;
        ctrl.addListener(() => count++);
        ctrl.add('a', const LayoutSize(width: 1, height: 1),
            strategy: PositionStrategy.append);
        expect(count, 1);
      });

      test('size is constrained to mainAxisSlots for horizontal axis', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        ctrl.add(
          'wide',
          const LayoutSize(width: 10, height: 1),
          strategy: PositionStrategy.append,
        );
        final item = ctrl.items.firstWhere((i) => i.id == 'wide');
        expect(item.rect.size.width, lessThanOrEqualTo(4));
      });

      test('size is constrained to mainAxisSlots for vertical axis', () {
        final ctrl = DashboardController(
          axis: DashboardAxis.vertical,
          mainAxisSlots: 3,
        );
        ctrl.add(
          'tall',
          const LayoutSize(width: 1, height: 99),
          strategy: PositionStrategy.append,
        );
        final item = ctrl.items.firstWhere((i) => i.id == 'tall');
        expect(item.rect.size.height, lessThanOrEqualTo(3));
      });

      test('duplicate id throws assertion error', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 1, 1)],
        );
        expect(
          () => ctrl.add(
            'a',
            const LayoutSize(width: 1, height: 1),
            strategy: PositionStrategy.append,
          ),
          throwsAssertionError,
        );
      });

      test('maxCrossAxisSlots grows when items occupy new cross rows', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        ctrl.add('a', const LayoutSize(width: 4, height: 1),
            strategy: PositionStrategy.append);
        expect(ctrl.maxCrossAxisSlots, 1); // bottom = y + height = 0 + 1 = 1
        ctrl.add('b', const LayoutSize(width: 4, height: 1),
            strategy: PositionStrategy.append);
        expect(ctrl.maxCrossAxisSlots, 2);
      });
    });

    group('add() — aggressive strategy', () {
      test('fills a gap in an existing layout', () {
        // Row 0: [a(0..2)] [gap(2..4)]
        // Row 1: [b(0..4)]
        // Aggressive should place 'c' at (2,0) filling the gap
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [
            _item('a', 0, 0, 2, 1),
            _item('b', 0, 1, 4, 1),
          ],
        );
        ctrl.add(
          'c',
          const LayoutSize(width: 2, height: 1),
          strategy: PositionStrategy.aggressive,
        );
        expect(ctrl.items.length, 3);
        _expectNoOverlaps(ctrl.items.toList());
        _expectNoOverflow(ctrl.items.toList(), DashboardAxis.horizontal, 4);

        final c = ctrl.items.firstWhere((i) => i.id == 'c');
        // Should fit in row 0 gap
        expect(c.rect.top, 0);
        expect(c.rect.left, 2);
      });

      test('falls back to new row when no gap fits', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 4, 1)],
        );
        ctrl.add('b', const LayoutSize(width: 3, height: 1),
            strategy: PositionStrategy.aggressive);
        expect(ctrl.items.length, 2);
        _expectNoOverlaps(ctrl.items.toList());
      });
    });

    group('add() — head strategy', () {
      test('places item before all existing items', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 1, 2, 1)],
        );
        ctrl.add(
          'head',
          const LayoutSize(width: 2, height: 1),
          strategy: PositionStrategy.head,
        );
        expect(ctrl.items.length, 2);
        _expectNoOverlaps(ctrl.items.toList());
      });
    });

    group('add() — after strategy', () {
      test('inserts item after the specified id', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [
            _item('a', 0, 0, 2, 1),
            _item('b', 2, 0, 2, 1),
          ],
        );
        ctrl.add(
          'c',
          const LayoutSize(width: 2, height: 1),
          strategy: PositionStrategy.after,
          afterId: 'a',
        );
        expect(ctrl.items.length, 3);
        expect(ctrl.items.any((i) => i.id == 'c'), isTrue);
        _expectNoOverlaps(ctrl.items.toList());
      });

      test('falls back to append when afterId is not found', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 2, 1)],
        );
        ctrl.add(
          'b',
          const LayoutSize(width: 2, height: 1),
          strategy: PositionStrategy.after,
          afterId: 'nonexistent',
        );
        expect(ctrl.items.length, 2);
        _expectNoOverlaps(ctrl.items.toList());
      });
    });

    // ── remove() ───────────────────────────────────────────────────────────

    group('remove()', () {
      test('removes the specified item', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 1, 1), _item('b', 1, 0, 1, 1)],
        );
        ctrl.remove('a');
        expect(ctrl.items.any((i) => i.id == 'a'), isFalse);
        expect(ctrl.items.length, 1);
      });

      test('remove triggers notifyListeners', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 1, 1)],
        );
        int count = 0;
        ctrl.addListener(() => count++);
        ctrl.remove('a');
        expect(count, 1);
      });

      test('removing non-existent id is a no-op (no notification)', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 1, 1)],
        );
        int count = 0;
        ctrl.addListener(() => count++);
        ctrl.remove('z');
        expect(count, 0);
        expect(ctrl.items.length, 1);
      });

      test('removing from empty controller is a no-op', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        expect(() => ctrl.remove('a'), returnsNormally);
        expect(ctrl.items, isEmpty);
      });

      test('maxCrossAxisSlots shrinks after tallest item removed', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [
            _item('tall', 0, 0, 2, 3), // bottom = 3
            _item('short', 2, 0, 2, 1), // bottom = 1
          ],
        );
        expect(ctrl.maxCrossAxisSlots, 3);
        ctrl.remove('tall');
        expect(ctrl.maxCrossAxisSlots, 1);
      });
    });

    // ── axis setter ────────────────────────────────────────────────────────

    group('axis setter', () {
      test('changing axis triggers notifyListeners', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        int count = 0;
        ctrl.addListener(() => count++);
        ctrl.axis = DashboardAxis.vertical;
        expect(count, 1);
        expect(ctrl.axis, DashboardAxis.vertical);
      });

      test('setting same axis does NOT trigger notifyListeners', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        int count = 0;
        ctrl.addListener(() => count++);
        ctrl.axis = DashboardAxis.horizontal; // same as default
        expect(count, 0);
      });

      test('axis change re-adopts item metrics (items remain valid)', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 2, 1)],
        );
        ctrl.axis = DashboardAxis.vertical;
        expect(ctrl.axis, DashboardAxis.vertical);
        expect(ctrl.items.length, 1);
        _expectNoOverflow(ctrl.items.toList(), DashboardAxis.vertical, 4);
      });
    });

    // ── mainAxisSlots setter ───────────────────────────────────────────────

    group('mainAxisSlots setter', () {
      test('changing mainAxisSlots triggers notifyListeners', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        int count = 0;
        ctrl.addListener(() => count++);
        ctrl.mainAxisSlots = 6;
        expect(count, 1);
        expect(ctrl.mainAxisSlots, 6);
      });

      test('setting same mainAxisSlots does NOT trigger notifyListeners', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        int count = 0;
        ctrl.addListener(() => count++);
        ctrl.mainAxisSlots = 4; // same value
        expect(count, 0);
      });

      test('decreasing mainAxisSlots re-adopts items to fit', () {
        final ctrl = DashboardController(
          mainAxisSlots: 6,
          initialItems: [_item('a', 0, 0, 6, 1)],
        );
        ctrl.mainAxisSlots = 2;
        expect(ctrl.mainAxisSlots, 2);
        _expectNoOverflow(ctrl.items.toList(), DashboardAxis.horizontal, 2);
      });

      test('increasing mainAxisSlots does not invalidate valid items', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 4, 1)],
        );
        ctrl.mainAxisSlots = 8;
        expect(ctrl.items.length, 1);
        expect(ctrl.items.first.id, 'a');
      });
    });

    // ── sortedItems ────────────────────────────────────────────────────────

    group('sortedItems', () {
      test('returns items sorted by axis (horizontal: primary y, secondary x)',
          () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [
            _item('b', 2, 0, 2, 1), // y=0, x=2
            _item('a', 0, 0, 2, 1), // y=0, x=0
          ],
        );
        final sorted = ctrl.sortedItems;
        expect(sorted[0].id, 'a');
        expect(sorted[1].id, 'b');
      });

      test('returns items sorted by axis (vertical: primary x, secondary y)',
          () {
        final ctrl = DashboardController(
          axis: DashboardAxis.vertical,
          mainAxisSlots: 4,
          initialItems: [
            _item('b', 0, 2, 1, 2), // x=0, y=2
            _item('a', 0, 0, 1, 2), // x=0, y=0
          ],
        );
        final sorted = ctrl.sortedItems;
        expect(sorted[0].id, 'a');
        expect(sorted[1].id, 'b');
      });

      test('sortedItems result is cached across multiple accesses', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 1, 1)],
        );
        final first = ctrl.sortedItems;
        final second = ctrl.sortedItems;
        expect(identical(first, second), isTrue);
      });

      test('sortedItems cache is invalidated when items change', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 1, 1)],
        );
        final before = ctrl.sortedItems;
        ctrl.add('b', const LayoutSize(width: 1, height: 1),
            strategy: PositionStrategy.append);
        final after = ctrl.sortedItems;
        expect(identical(before, after), isFalse);
      });

      test('sortedItems cache is invalidated when axis changes', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 1, 1)],
        );
        final before = ctrl.sortedItems;
        ctrl.axis = DashboardAxis.vertical;
        final after = ctrl.sortedItems;
        expect(identical(before, after), isFalse);
      });
    });

    // ── dispose ────────────────────────────────────────────────────────────

    test('controller can be disposed without error', () {
      final ctrl = DashboardController(mainAxisSlots: 4);
      expect(() => ctrl.dispose(), returnsNormally);
    });

    // ── integration: multiple operations ──────────────────────────────────

    group('integration: sequence of add/remove', () {
      test('add then remove restores original state', () {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 2, 1)],
        );
        ctrl.add('b', const LayoutSize(width: 2, height: 1),
            strategy: PositionStrategy.append);
        expect(ctrl.items.length, 2);
        ctrl.remove('b');
        expect(ctrl.items.length, 1);
        expect(ctrl.items.first.id, 'a');
      });

      test('multiple adds produce valid non-overlapping layout', () {
        final ctrl = DashboardController(mainAxisSlots: 4);
        for (int i = 0; i < 8; i++) {
          ctrl.add(
            'item_$i',
            const LayoutSize(width: 2, height: 1),
            strategy: PositionStrategy.append,
          );
        }
        expect(ctrl.items.length, 8);
        _expectNoOverlaps(ctrl.items.toList());
        _expectNoOverflow(ctrl.items.toList(), DashboardAxis.horizontal, 4);
      });
    });
  });
}
