import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/sliver/child_delegate.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

LayoutItem _item(String id, int x, int y, int w, int h) => LayoutItem(
  id: id,
  rect: LayoutRect(x: x, y: y, size: LayoutSize(width: w, height: h)),
);

/// A test widget that implements [LayoutItemWidget].
class _TestLayoutItemWidget extends StatelessWidget with LayoutItemWidget {
  @override
  final LayoutItem item;

  const _TestLayoutItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('content_${item.id}'),
      color: Colors.blue,
      child: Text(item.id.toString()),
    );
  }
}

/// Wraps [child] with a [MaterialApp] and a 400×600 [SizedBox].
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 400, height: 600, child: child),
    ),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── Dashboard widget ───────────────────────────────────────────────────────

  group('Dashboard', () {
    group('empty state', () {
      testWidgets('shows emptyBuilder when items is empty', (tester) async {
        final ctrl = DashboardController(mainAxisSlots: 4);

        await tester.pumpWidget(
          _wrap(
            Dashboard(
              controller: ctrl,
              itemBuilder: (_, item) => Container(key: ValueKey(item.id)),
              emptyBuilder: (_) => const Text('Empty!'),
            ),
          ),
        );

        expect(find.text('Empty!'), findsOneWidget);
      });

      testWidgets(
        'hides emptyBuilder when items are present',
        (tester) async {
          final ctrl = DashboardController(
            mainAxisSlots: 4,
            initialItems: [_item('a', 0, 0, 4, 1)],
          );

          await tester.pumpWidget(
            _wrap(
              Dashboard(
                controller: ctrl,
                itemBuilder: (_, item) =>
                    Container(key: ValueKey(item.id), child: Text(item.id.toString())),
                emptyBuilder: (_) => const Text('Empty!'),
              ),
            ),
          );
          await tester.pump();

          expect(find.text('Empty!'), findsNothing);
        },
      );

      testWidgets(
        'no emptyBuilder: renders empty without error when items is empty',
        (tester) async {
          final ctrl = DashboardController(mainAxisSlots: 4);

          await tester.pumpWidget(
            _wrap(
              Dashboard(
                controller: ctrl,
                itemBuilder: (_, item) => Container(),
              ),
            ),
          );

          // Should render without assertion failures
          expect(find.byType(Dashboard), findsOneWidget);
        },
      );
    });

    group('loading state', () {
      testWidgets(
        'shows default CircularProgressIndicator when isLoading=true',
        (tester) async {
          final ctrl = DashboardController(mainAxisSlots: 4);
          final isLoading = ValueNotifier(true);

          await tester.pumpWidget(
            _wrap(
              Dashboard(
                controller: ctrl,
                itemBuilder: (_, item) => Container(),
                isLoading: isLoading,
              ),
            ),
          );

          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
      );

      testWidgets(
        'hides loader and shows empty placeholder when isLoading=false, items empty',
        (tester) async {
          final ctrl = DashboardController(mainAxisSlots: 4);
          final isLoading = ValueNotifier(false);

          await tester.pumpWidget(
            _wrap(
              Dashboard(
                controller: ctrl,
                itemBuilder: (_, item) => Container(),
                isLoading: isLoading,
                emptyBuilder: (_) => const Text('No items'),
              ),
            ),
          );

          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.text('No items'), findsOneWidget);
        },
      );

      testWidgets('shows custom loadingBuilder instead of default indicator',
          (tester) async {
        final ctrl = DashboardController(mainAxisSlots: 4);
        final isLoading = ValueNotifier(true);

        await tester.pumpWidget(
          _wrap(
            Dashboard(
              controller: ctrl,
              itemBuilder: (_, item) => Container(),
              isLoading: isLoading,
              loadingBuilder: (_) => const Text('Loading…'),
            ),
          ),
        );

        expect(find.text('Loading…'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets(
        'transitions: loading=true → loading=false → empty shows correctly',
        (tester) async {
          final ctrl = DashboardController(mainAxisSlots: 4);
          final isLoading = ValueNotifier(true);

          await tester.pumpWidget(
            _wrap(
              Dashboard(
                controller: ctrl,
                itemBuilder: (_, item) => Container(),
                isLoading: isLoading,
                emptyBuilder: (_) => const Text('Empty'),
              ),
            ),
          );
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.text('Empty'), findsNothing);

          isLoading.value = false;
          await tester.pump();

          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.text('Empty'), findsOneWidget);
        },
      );
    });

    group('controller integration', () {
      testWidgets('rebuilds when controller adds an item', (tester) async {
        final ctrl = DashboardController(mainAxisSlots: 4);

        await tester.pumpWidget(
          _wrap(
            Dashboard(
              controller: ctrl,
              itemBuilder: (_, item) =>
                  Container(key: ValueKey(item.id), child: Text(item.id.toString())),
              emptyBuilder: (_) => const Text('Empty'),
            ),
          ),
        );

        expect(find.text('Empty'), findsOneWidget);
        expect(find.text('a'), findsNothing);

        ctrl.add('a', const LayoutSize(width: 4, height: 1),
            strategy: PositionStrategy.append);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(find.text('Empty'), findsNothing);
        expect(find.text('a'), findsOneWidget);
      });

      testWidgets('rebuilds when controller removes an item', (tester) async {
        final ctrl = DashboardController(
          mainAxisSlots: 4,
          initialItems: [_item('a', 0, 0, 4, 1)],
        );

        await tester.pumpWidget(
          _wrap(
            Dashboard(
              controller: ctrl,
              itemBuilder: (_, item) =>
                  Container(key: ValueKey(item.id), child: Text(item.id.toString())),
              emptyBuilder: (_) => const Text('Empty'),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('a'), findsOneWidget);

        ctrl.remove('a');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(find.text('a'), findsNothing);
        expect(find.text('Empty'), findsOneWidget);
      });
    });
  });

  // ── DashboardView ──────────────────────────────────────────────────────────

  group('DashboardView', () {
    group('DashboardView.builder', () {
      testWidgets('renders with empty items without error', (tester) async {
        await tester.pumpWidget(
          _wrap(
            DashboardView.builder(
              axis: DashboardAxis.horizontal,
              mainAxisSlots: 4,
              items: [],
              itemBuilder: (_, item) => Container(),
            ),
          ),
        );
        expect(find.byType(DashboardView), findsOneWidget);
      });

      testWidgets('renders all items via itemBuilder', (tester) async {
        final items = [
          _item('a', 0, 0, 2, 1),
          _item('b', 2, 0, 2, 1),
        ];

        await tester.pumpWidget(
          _wrap(
            DashboardView.builder(
              axis: DashboardAxis.horizontal,
              mainAxisSlots: 4,
              items: items,
              itemBuilder: (_, item) =>
                  Container(key: ValueKey(item.id), child: Text(item.id.toString())),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('a'), findsOneWidget);
        expect(find.text('b'), findsOneWidget);
      });

      testWidgets('horizontal axis → scroll direction is vertical', (tester) async {
        await tester.pumpWidget(
          _wrap(
            DashboardView.builder(
              axis: DashboardAxis.horizontal,
              mainAxisSlots: 4,
              items: [],
              itemBuilder: (_, item) => Container(),
            ),
          ),
        );

        final scrollable = tester.widget<Scrollable>(find.byType(Scrollable));
        expect(scrollable.axisDirection, anyOf(AxisDirection.down, AxisDirection.up));
      });

      testWidgets('vertical axis → scroll direction is horizontal', (tester) async {
        await tester.pumpWidget(
          _wrap(
            DashboardView.builder(
              axis: DashboardAxis.vertical,
              mainAxisSlots: 4,
              items: [],
              itemBuilder: (_, item) => Container(),
            ),
          ),
        );

        final scrollable = tester.widget<Scrollable>(find.byType(Scrollable));
        expect(scrollable.axisDirection, anyOf(AxisDirection.left, AxisDirection.right));
      });

      testWidgets('items are scrollable when content exceeds viewport',
          (tester) async {
        // Create many rows that exceed the 600px viewport height
        final items = List.generate(
          20,
          (i) => _item('item_$i', 0, i, 4, 1),
        );

        await tester.pumpWidget(
          _wrap(
            DashboardView.builder(
              axis: DashboardAxis.horizontal,
              mainAxisSlots: 4,
              items: items,
              aspectRatio: 0.25, // tall slots to force scrolling
              itemBuilder: (_, item) =>
                  Container(key: ValueKey(item.id), child: Text(item.id.toString())),
            ),
          ),
        );
        await tester.pump();

        // The widget renders without layout failures
        expect(find.byType(DashboardView), findsOneWidget);
      });
    });

    group('DashboardView.list', () {
      testWidgets('renders children via list constructor', (tester) async {
        final items = [
          _item('x', 0, 0, 2, 1),
          _item('y', 2, 0, 2, 1),
        ];
        final children = items
            .map((item) => _TestLayoutItemWidget(key: ValueKey(item.id), item: item))
            .toList();

        await tester.pumpWidget(
          _wrap(
            DashboardView.list(
              axis: DashboardAxis.horizontal,
              mainAxisSlots: 4,
              children: children,
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const ValueKey('content_x')), findsOneWidget);
        expect(find.byKey(const ValueKey('content_y')), findsOneWidget);
      });

      testWidgets('renders with empty children list without error', (tester) async {
        await tester.pumpWidget(
          _wrap(
            DashboardView.list(
              axis: DashboardAxis.horizontal,
              mainAxisSlots: 4,
              children: [],
            ),
          ),
        );
        expect(find.byType(DashboardView), findsOneWidget);
      });
    });

    group('DashboardView default constructor', () {
      testWidgets('accepts explicit layoutDelegate and delegate', (tester) async {
        final items = [_item('a', 0, 0, 4, 1)];
        final layoutDelegate = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: items,
          axis: DashboardAxis.horizontal,
        );
        final childDelegate = SliverDashboardBuilderDelegate.items(
          items: items,
          builder: (_, item) =>
              Container(key: ValueKey(item.id), child: Text(item.id.toString())),
        );

        await tester.pumpWidget(
          _wrap(
            DashboardView(
              layoutDelegate: layoutDelegate,
              delegate: childDelegate,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('a'), findsOneWidget);
      });
    });
  });

  // ── SliverDashboard ────────────────────────────────────────────────────────

  group('SliverDashboard (via CustomScrollView)', () {
    testWidgets('renders items inside a CustomScrollView', (tester) async {
      final items = [
        _item('p', 0, 0, 2, 1),
        _item('q', 2, 0, 2, 1),
      ];
      final layoutDelegate = SliverDashboardDelegateWithFixedSlotCount(
        mainAxisSlots: 4,
        items: items,
        axis: DashboardAxis.horizontal,
      );
      final childDelegate = SliverDashboardBuilderDelegate.items(
        items: items,
        builder: (_, item) =>
            Container(key: ValueKey(item.id), child: Text(item.id.toString())),
      );

      await tester.pumpWidget(
        _wrap(
          CustomScrollView(
            scrollDirection: Axis.vertical, // perpendicular to horizontal dashboard
            slivers: [
              SliverDashboard(
                layoutDelegate: layoutDelegate,
                delegate: childDelegate,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('p'), findsOneWidget);
      expect(find.text('q'), findsOneWidget);
    });

    testWidgets('SliverDashboard.builder convenience constructor renders items',
        (tester) async {
      final items = [_item('r', 0, 0, 4, 1)];

      await tester.pumpWidget(
        _wrap(
          CustomScrollView(
            scrollDirection: Axis.vertical,
            slivers: [
              SliverDashboard.builder(
                axis: DashboardAxis.horizontal,
                mainAxisSlots: 4,
                items: items,
                itemBuilder: (_, item) =>
                    Container(key: ValueKey(item.id), child: Text(item.id.toString())),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('r'), findsOneWidget);
    });

    testWidgets('SliverDashboard.list convenience constructor renders children',
        (tester) async {
      final item = _item('s', 0, 0, 4, 1);
      final child = _TestLayoutItemWidget(item: item);

      await tester.pumpWidget(
        _wrap(
          CustomScrollView(
            scrollDirection: Axis.vertical,
            slivers: [
              SliverDashboard.list(
                axis: DashboardAxis.horizontal,
                mainAxisSlots: 4,
                children: [child],
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('content_s')), findsOneWidget);
    });
  });
}
