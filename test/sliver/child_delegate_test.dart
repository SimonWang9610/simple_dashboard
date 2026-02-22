import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

LayoutItem _item(String id, int x, int y, int w, int h) => LayoutItem(
  id: id,
  rect: LayoutRect(
    x: x,
    y: y,
    size: LayoutSize(width: w, height: h),
  ),
);

/// Recursively checks whether a [RepaintBoundary] exists anywhere in the
/// immediate widget tree (without inflating).
bool _hasType<T extends Widget>(Widget root) {
  if (root is T) return true;
  if (root is KeyedSubtree) return _hasType<T>(root.child);
  if (root is AutomaticKeepAlive) {
    return _hasType<T>(root.child);
  }
  if (root is IndexedSemantics) {
    return root.child != null && _hasType<T>(root.child!);
  }
  if (root is RepaintBoundary) return T == RepaintBoundary;
  return false;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── SliverDashboardBuilderDelegate ────────────────────────────────────────

  group('SliverDashboardBuilderDelegate', () {
    group('.items() constructor', () {
      test('estimatedChildCount matches items.length', () {
        final items = [_item('a', 0, 0, 1, 1), _item('b', 1, 0, 1, 1)];
        final delegate = SliverDashboardBuilderDelegate.items(
          items: items,
          builder: (_, item) => Container(key: ValueKey(item.id)),
        );
        expect(delegate.estimatedChildCount, 2);
      });

      test('estimatedChildCount is 0 for empty items', () {
        final delegate = SliverDashboardBuilderDelegate.items(
          items: [],
          builder: (_, item) => Container(),
        );
        expect(delegate.estimatedChildCount, 0);
      });

      test('findIndexByKey returns null for a plain ValueKey', () {
        final items = [_item('a', 0, 0, 1, 1)];
        final delegate = SliverDashboardBuilderDelegate.items(
          items: items,
          builder: (_, item) => Container(),
        );
        expect(delegate.findIndexByKey(const ValueKey('a')), isNull);
      });

      test('itemKeyForIndex returns null for out-of-range index', () {
        final items = [_item('a', 0, 0, 1, 1)];
        final delegate = SliverDashboardBuilderDelegate.items(
          items: items,
          builder: (_, item) => Container(),
        );
        expect(delegate.itemKeyForIndex(99, null), isNull);
        expect(delegate.itemKeyForIndex(-1, null), isNull);
      });

      test('itemKeyForIndex returns subKey as fallback for out-of-range', () {
        final delegate = SliverDashboardBuilderDelegate.items(
          items: [],
          builder: (_, item) => Container(),
        );
        const subKey = ValueKey('fallback');
        expect(delegate.itemKeyForIndex(0, subKey), subKey);
      });

      test('key round-trip: itemKeyForIndex → findIndexByKey', () {
        final items = [
          _item('a', 0, 0, 1, 1),
          _item('b', 1, 0, 1, 1),
          _item('c', 2, 0, 1, 1),
        ];
        final delegate = SliverDashboardBuilderDelegate.items(
          items: items,
          builder: (_, item) => Container(),
        );
        for (int i = 0; i < items.length; i++) {
          final key = delegate.itemKeyForIndex(i, null)!;
          expect(delegate.findIndexByKey(key), i);
        }
      });

      test('keys for different items are distinct', () {
        final items = [_item('a', 0, 0, 1, 1), _item('b', 1, 0, 1, 1)];
        final delegate = SliverDashboardBuilderDelegate.items(
          items: items,
          builder: (_, item) => Container(),
        );
        final key0 = delegate.itemKeyForIndex(0, null);
        final key1 = delegate.itemKeyForIndex(1, null);
        expect(key0, isNot(equals(key1)));
      });
    });

    group('base constructor', () {
      test('estimatedChildCount reflects childCount param', () {
        final delegate = SliverDashboardBuilderDelegate(
          childCount: 7,
          findItemByIndex: (_) => null,
          builder: (_, item) => Container(),
        );
        expect(delegate.estimatedChildCount, 7);
      });

      test('estimatedChildCount is null when childCount not provided', () {
        final delegate = SliverDashboardBuilderDelegate(
          findItemByIndex: (_) => null,
          builder: (_, item) => Container(),
        );
        expect(delegate.estimatedChildCount, isNull);
      });

      test('shouldRebuild always returns true (conservative default)', () {
        final delegate = SliverDashboardBuilderDelegate(
          findItemByIndex: (_) => null,
          builder: (_, item) => Container(),
        );
        // shouldRebuild(old) — both parameters are the same object
        expect(delegate.shouldRebuild(delegate), isTrue);
      });
    });

    group('build() wrapping', () {
      testWidgets(
        'wraps child in RepaintBoundary when addRepaintBoundaries=true',
        (tester) async {
          final items = [_item('a', 0, 0, 1, 1)];
          late BuildContext ctx;

          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  ctx = context;
                  return Container();
                },
              ),
            ),
          );

          final delegate = SliverDashboardBuilderDelegate.items(
            items: items,
            builder: (_, item) => Text(item.id.toString()),
            addRepaintBoundaries: true,
            addSemanticIndexes: false,
            addAutomaticKeepAlives: false,
          );

          final built = delegate.build(ctx, 0)!;
          // KeyedSubtree(child: RepaintBoundary(child: Text))
          expect(built, isA<KeyedSubtree>());
          expect(_hasType<RepaintBoundary>(built), isTrue);
        },
      );

      testWidgets(
        'does NOT wrap with RepaintBoundary when addRepaintBoundaries=false',
        (tester) async {
          final items = [_item('a', 0, 0, 1, 1)];
          late BuildContext ctx;

          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  ctx = context;
                  return Container();
                },
              ),
            ),
          );

          final delegate = SliverDashboardBuilderDelegate.items(
            items: items,
            builder: (_, item) => Text(item.id.toString()),
            addRepaintBoundaries: false,
            addSemanticIndexes: false,
            addAutomaticKeepAlives: false,
          );

          final built = delegate.build(ctx, 0)!;
          expect(_hasType<RepaintBoundary>(built), isFalse);
        },
      );

      testWidgets(
        'wraps child in AutomaticKeepAlive when addAutomaticKeepAlives=true',
        (tester) async {
          final items = [_item('a', 0, 0, 1, 1)];
          late BuildContext ctx;

          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  ctx = context;
                  return Container();
                },
              ),
            ),
          );

          final delegate = SliverDashboardBuilderDelegate.items(
            items: items,
            builder: (_, item) => Text(item.id.toString()),
            addRepaintBoundaries: false,
            addSemanticIndexes: false,
            addAutomaticKeepAlives: true,
          );

          final built = delegate.build(ctx, 0)!;
          expect(built, isA<KeyedSubtree>());
          expect((built as KeyedSubtree).child, isA<AutomaticKeepAlive>());
        },
      );

      testWidgets(
        'wraps child in IndexedSemantics when addSemanticIndexes=true',
        (tester) async {
          final items = [_item('a', 0, 0, 1, 1)];
          late BuildContext ctx;

          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  ctx = context;
                  return Container();
                },
              ),
            ),
          );

          final delegate = SliverDashboardBuilderDelegate.items(
            items: items,
            builder: (_, item) => Text(item.id.toString()),
            addRepaintBoundaries: false,
            addSemanticIndexes: true,
            addAutomaticKeepAlives: false,
          );

          final built = delegate.build(ctx, 0)!;
          // KeyedSubtree → IndexedSemantics
          expect(built, isA<KeyedSubtree>());
          expect(
            (built as KeyedSubtree).child,
            isA<IndexedSemantics>(),
          );
        },
      );

      testWidgets('build returns null for out-of-range index', (tester) async {
        final items = [_item('a', 0, 0, 1, 1)];
        late BuildContext ctx;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                ctx = context;
                return Container();
              },
            ),
          ),
        );

        final delegate = SliverDashboardBuilderDelegate.items(
          items: items,
          builder: (_, item) => Container(),
        );

        expect(delegate.build(ctx, 99), isNull);
      });

      testWidgets(
        'build returns ErrorWidget when builder throws',
        (tester) async {
          final items = [_item('a', 0, 0, 1, 1)];
          late BuildContext ctx;

          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  ctx = context;
                  return Container();
                },
              ),
            ),
          );

          final delegate = SliverDashboardBuilderDelegate.items(
            items: items,
            builder: (_, item) => throw Exception('test error'),
            addRepaintBoundaries: false,
            addSemanticIndexes: false,
            addAutomaticKeepAlives: false,
          );

          // Suppress the FlutterError that gets reported before calling build
          final previousHandler = FlutterError.onError;
          FlutterError.onError = (_) {};
          addTearDown(() => FlutterError.onError = previousHandler);

          // Should not throw; error is caught and replaced with ErrorWidget
          final built = delegate.build(ctx, 0);
          expect(built, isNotNull);
        },
      );
    });
  });

  // ── SliverDashboardListDelegate ───────────────────────────────────────────

  group('SliverDashboardListDelegate', () {
    test('estimatedChildCount equals children.length', () {
      final delegate = SliverDashboardListDelegate(
        children: [Container(), Container(), Container()],
      );
      expect(delegate.estimatedChildCount, 3);
    });

    test('estimatedChildCount is 0 for empty children', () {
      final delegate = SliverDashboardListDelegate(children: []);
      expect(delegate.estimatedChildCount, 0);
    });

    testWidgets('buildItemWidget returns null for negative index', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return Container();
            },
          ),
        ),
      );
      final delegate = SliverDashboardListDelegate(children: [Container()]);
      expect(delegate.buildItemWidget(ctx, -1), isNull);
    });

    testWidgets('buildItemWidget returns null when index >= length', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return Container();
            },
          ),
        ),
      );
      final delegate = SliverDashboardListDelegate(children: [Container()]);
      expect(delegate.buildItemWidget(ctx, 1), isNull);
    });

    testWidgets('buildItemWidget returns the correct child at each index', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return Container();
            },
          ),
        ),
      );
      final a = Container(key: const ValueKey('a'));
      final b = Container(key: const ValueKey('b'));
      final delegate = SliverDashboardListDelegate(children: [a, b]);
      expect(delegate.buildItemWidget(ctx, 0), same(a));
      expect(delegate.buildItemWidget(ctx, 1), same(b));
    });

    test('itemKeyForIndex returns subKey when findItemByIndex is null', () {
      final delegate = SliverDashboardListDelegate(children: [Container()]);
      const subKey = ValueKey('x');
      expect(delegate.itemKeyForIndex(0, subKey), subKey);
    });

    test(
      'itemKeyForIndex returns subKey when findItemByIndex returns null',
      () {
        final delegate = SliverDashboardListDelegate(
          children: [Container()],
          findItemByIndex: (_) => null,
        );
        const subKey = ValueKey('x');
        expect(delegate.itemKeyForIndex(0, subKey), subKey);
      },
    );

    test('findIndexByKey returns null for a plain ValueKey', () {
      final delegate = SliverDashboardListDelegate(children: [Container()]);
      expect(delegate.findIndexByKey(const ValueKey('a')), isNull);
    });

    test('key round-trip: itemKeyForIndex → findIndexByKey', () {
      final items = [_item('a', 0, 0, 1, 1), _item('b', 1, 0, 1, 1)];
      final delegate = SliverDashboardListDelegate(
        children: [Container(), Container()],
        findItemByIndex: (i) => i < items.length ? items[i] : null,
        findItemIndexById: (id) {
          final idx = items.indexWhere((item) => item.id == id);
          return idx >= 0 ? idx : null;
        },
      );
      final key0 = delegate.itemKeyForIndex(0, null)!;
      expect(delegate.findIndexByKey(key0), 0);

      final key1 = delegate.itemKeyForIndex(1, null)!;
      expect(delegate.findIndexByKey(key1), 1);
    });

    test('keys for different items are distinct', () {
      final items = [_item('a', 0, 0, 1, 1), _item('b', 1, 0, 1, 1)];
      final delegate = SliverDashboardListDelegate(
        children: [Container(), Container()],
        findItemByIndex: (i) => i < items.length ? items[i] : null,
      );
      final key0 = delegate.itemKeyForIndex(0, null);
      final key1 = delegate.itemKeyForIndex(1, null);
      expect(key0, isNot(equals(key1)));
    });

    test('shouldRebuild always returns true (conservative default)', () {
      final delegate = SliverDashboardListDelegate(children: []);
      expect(delegate.shouldRebuild(delegate), isTrue);
    });

    group('build() wrapping', () {
      testWidgets(
        'wraps child in RepaintBoundary when addRepaintBoundaries=true',
        (tester) async {
          late BuildContext ctx;

          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  ctx = context;
                  return Container();
                },
              ),
            ),
          );

          final delegate = SliverDashboardListDelegate(
            children: [const Text('hello')],
            addRepaintBoundaries: true,
            addSemanticIndexes: false,
            addAutomaticKeepAlives: false,
          );

          final built = delegate.build(ctx, 0)!;
          expect(_hasType<RepaintBoundary>(built), isTrue);
        },
      );

      testWidgets(
        'does NOT wrap with RepaintBoundary when addRepaintBoundaries=false',
        (tester) async {
          late BuildContext ctx;

          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  ctx = context;
                  return Container();
                },
              ),
            ),
          );

          final delegate = SliverDashboardListDelegate(
            children: [const Text('hello')],
            addRepaintBoundaries: false,
            addSemanticIndexes: false,
            addAutomaticKeepAlives: false,
          );

          final built = delegate.build(ctx, 0)!;
          expect(_hasType<RepaintBoundary>(built), isFalse);
        },
      );
    });
  });
}
