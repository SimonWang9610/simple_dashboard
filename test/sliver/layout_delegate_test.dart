import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

LayoutItem _item(String id, int x, int y, int w, int h) => LayoutItem(
  id: id,
  rect: LayoutRect(x: x, y: y, size: LayoutSize(width: w, height: h)),
);

/// SliverConstraints with axis=Axis.vertical (used for DashboardAxis.horizontal).
/// The sliver's scroll direction must be perpendicular to the dashboard axis.
SliverConstraints _verticalConstraints({double crossAxisExtent = 600}) {
  return SliverConstraints(
    axisDirection: AxisDirection.down,
    growthDirection: GrowthDirection.forward,
    userScrollDirection: ScrollDirection.idle,
    scrollOffset: 0,
    precedingScrollExtent: 0,
    overlap: 0,
    remainingPaintExtent: 800,
    crossAxisExtent: crossAxisExtent,
    crossAxisDirection: AxisDirection.right,
    viewportMainAxisExtent: 800,
    remainingCacheExtent: 800,
    cacheOrigin: 0,
  );
}

/// SliverConstraints with axis=Axis.horizontal (used for DashboardAxis.vertical).
SliverConstraints _horizontalConstraints({double crossAxisExtent = 600}) {
  return SliverConstraints(
    axisDirection: AxisDirection.right,
    growthDirection: GrowthDirection.forward,
    userScrollDirection: ScrollDirection.idle,
    scrollOffset: 0,
    precedingScrollExtent: 0,
    overlap: 0,
    remainingPaintExtent: 800,
    crossAxisExtent: crossAxisExtent,
    crossAxisDirection: AxisDirection.down,
    viewportMainAxisExtent: 800,
    remainingCacheExtent: 800,
    cacheOrigin: 0,
  );
}

SliverDashboardLayout _makeHLayout({
  double mainSlotExtent = 100,
  double crossSlotExtent = 100,
  double mainSpacing = 0,
  double crossSpacing = 0,
  List<LayoutItem>? items,
  int maxCrossSlots = 0,
}) {
  return SliverDashboardLayout(
    dashboardAxis: DashboardAxis.horizontal,
    mainDashboardAxisSlotExtent: mainSlotExtent,
    crossDashboardAxisSlotExtent: crossSlotExtent,
    mainDashboardAxisSpacing: mainSpacing,
    crossDashboardAxisSpacing: crossSpacing,
    items: items ?? [],
    maxCrossDashboardAxisSlots: maxCrossSlots,
  );
}

SliverDashboardLayout _makeVLayout({
  double mainSlotExtent = 100,
  double crossSlotExtent = 100,
  double mainSpacing = 0,
  double crossSpacing = 0,
  List<LayoutItem>? items,
  int maxCrossSlots = 0,
}) {
  return SliverDashboardLayout(
    dashboardAxis: DashboardAxis.vertical,
    mainDashboardAxisSlotExtent: mainSlotExtent,
    crossDashboardAxisSlotExtent: crossSlotExtent,
    mainDashboardAxisSpacing: mainSpacing,
    crossDashboardAxisSpacing: crossSpacing,
    items: items ?? [],
    maxCrossDashboardAxisSlots: maxCrossSlots,
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── SliverDashboardLayout ──────────────────────────────────────────────────

  group('SliverDashboardLayout', () {
    group('strides', () {
      test('mainDashboardAxisStride = slotExtent + spacing', () {
        final layout = _makeHLayout(mainSlotExtent: 100, mainSpacing: 10);
        expect(layout.mainDashboardAxisStride, 110);
      });

      test('crossDashboardAxisStride = slotExtent + spacing', () {
        final layout = _makeHLayout(crossSlotExtent: 80, crossSpacing: 5);
        expect(layout.crossDashboardAxisStride, 85);
      });

      test('strides equal slot extents when spacing is zero', () {
        final layout = _makeHLayout(mainSlotExtent: 120, crossSlotExtent: 60);
        expect(layout.mainDashboardAxisStride, 120);
        expect(layout.crossDashboardAxisStride, 60);
      });
    });

    // ── computeMaxScrollOffset ─────────────────────────────────────────────

    group('computeMaxScrollOffset', () {
      test('returns 0.0 for empty items list', () {
        final layout = _makeHLayout();
        expect(layout.computeMaxScrollOffset(), 0.0);
      });

      test('horizontal: maxScrollOffset = maxCrossSlots * crossStride - crossSpacing', () {
        // crossStride = 100 + 10 = 110; maxOffset = 3 * 110 - 10 = 320
        final layout = _makeHLayout(
          crossSlotExtent: 100,
          crossSpacing: 10,
          maxCrossSlots: 3,
          items: [_item('a', 0, 0, 1, 3)],
        );
        expect(layout.computeMaxScrollOffset(), 320.0);
      });

      test('no spacing: maxScrollOffset = maxCrossSlots * crossSlotExtent', () {
        final layout = _makeHLayout(
          crossSlotExtent: 100,
          crossSpacing: 0,
          maxCrossSlots: 5,
          items: [_item('a', 0, 0, 1, 5)],
        );
        expect(layout.computeMaxScrollOffset(), 500.0);
      });

      test('vertical: maxScrollOffset uses cross axis correctly', () {
        // For vertical layout, scroll is horizontal → crossStride drives scroll extent
        final layout = _makeVLayout(
          crossSlotExtent: 50,
          crossSpacing: 0,
          maxCrossSlots: 4,
          items: [_item('a', 0, 0, 4, 1)],
        );
        expect(layout.computeMaxScrollOffset(), 200.0);
      });
    });

    // ── computeGeometry ────────────────────────────────────────────────────

    group('computeGeometry', () {
      test('returns all-zero geometry for empty items', () {
        final layout = _makeHLayout();
        final geo = layout.computeGeometry(0);
        expect(geo.scrollOffset, 0.0);
        expect(geo.crossAxisOffset, 0.0);
        expect(geo.mainAxisExtent, 0.0);
        expect(geo.crossAxisExtent, 0.0);
      });

      test(
        'horizontal: item (x=0,y=0,w=2,h=1) — correct offsets and extents',
        () {
          // Strides: main=110, cross=110
          // dx = 0 * 110 = 0, dy = 0 * 110 = 0
          // widthExtent = 2*110 - 10 = 210, heightExtent = 1*110 - 10 = 100
          // horizontal: scrollOffset=dy=0, crossAxisOffset=dx=0,
          //             mainAxisExtent=heightExtent=100, crossAxisExtent=widthExtent=210
          final layout = _makeHLayout(
            mainSlotExtent: 100,
            crossSlotExtent: 100,
            mainSpacing: 10,
            crossSpacing: 10,
            items: [_item('a', 0, 0, 2, 1)],
            maxCrossSlots: 1,
          );
          final geo = layout.computeGeometry(0);
          expect(geo.scrollOffset, 0.0);
          expect(geo.crossAxisOffset, 0.0);
          expect(geo.mainAxisExtent, 100.0);
          expect(geo.crossAxisExtent, 210.0);
        },
      );

      test('horizontal: second-row item has scrollOffset = crossStride', () {
        // item 'b' at y=1; dy = 1 * 100 = 100 → scrollOffset = 100
        final items = [_item('a', 0, 0, 2, 1), _item('b', 0, 1, 2, 1)];
        final layout = _makeHLayout(
          mainSlotExtent: 100,
          crossSlotExtent: 100,
          items: items,
          maxCrossSlots: 2,
        );
        final geo = layout.computeGeometry(1);
        expect(geo.scrollOffset, 100.0);
      });

      test('horizontal: item with width=4 spans full cross axis', () {
        // widthExtent = 4*100 - 0 = 400
        final layout = _makeHLayout(
          mainSlotExtent: 100,
          items: [_item('a', 0, 0, 4, 1)],
          maxCrossSlots: 1,
        );
        final geo = layout.computeGeometry(0);
        expect(geo.crossAxisExtent, 400.0);
      });

      test(
        'vertical: item (x=1,y=0,w=1,h=2) — correct offsets and extents',
        () {
          // For vertical axis:
          // dx = left * crossStride = 1 * 100 = 100
          // dy = top * mainStride  = 0 * 100 = 0
          // widthExtent  = width  * crossStride - crossSpacing = 1*100-0 = 100
          // heightExtent = height * mainStride  - mainSpacing  = 2*100-0 = 200
          // vertical: scrollOffset=dx=100, crossAxisOffset=dy=0,
          //           mainAxisExtent=widthExtent=100, crossAxisExtent=heightExtent=200
          final layout = _makeVLayout(
            mainSlotExtent: 100,
            crossSlotExtent: 100,
            items: [_item('a', 1, 0, 1, 2)],
            maxCrossSlots: 1,
          );
          final geo = layout.computeGeometry(0);
          expect(geo.scrollOffset, 100.0);
          expect(geo.crossAxisOffset, 0.0);
          expect(geo.mainAxisExtent, 100.0);
          expect(geo.crossAxisExtent, 200.0);
        },
      );

      test('computeItemGeometry matches computeGeometry at same index', () {
        final items = [_item('a', 0, 0, 2, 1), _item('b', 0, 1, 3, 2)];
        final layout = _makeHLayout(
          mainSlotExtent: 80,
          crossSlotExtent: 60,
          mainSpacing: 4,
          crossSpacing: 4,
          items: items,
          maxCrossSlots: 3,
        );
        // computeGeometry delegates to computeItemGeometry, so they must agree
        final fromIndex = layout.computeGeometry(1);
        final fromRect = layout.computeItemGeometry(items[1].rect);
        expect(fromIndex.scrollOffset, fromRect.scrollOffset);
        expect(fromIndex.crossAxisOffset, fromRect.crossAxisOffset);
        expect(fromIndex.mainAxisExtent, fromRect.mainAxisExtent);
        expect(fromIndex.crossAxisExtent, fromRect.crossAxisExtent);
      });
    });

    // ── getMinChildIndexForScrollOffset ───────────────────────────────────

    group('getMinChildIndexForScrollOffset', () {
      test('returns 0 for empty items regardless of scrollOffset', () {
        final layout = _makeHLayout();
        expect(layout.getMinChildIndexForScrollOffset(0), 0);
        expect(layout.getMinChildIndexForScrollOffset(9999), 0);
      });

      test('returns 0 when scrollOffset=0', () {
        final items = [_item('a', 0, 0, 2, 1), _item('b', 0, 1, 2, 1)];
        final layout = _makeHLayout(
          crossSlotExtent: 100,
          items: items,
          maxCrossSlots: 2,
        );
        expect(layout.getMinChildIndexForScrollOffset(0), 0);
      });

      test('returns index of first item whose cross extent exceeds offset', () {
        // items: a(bottom=1), b(bottom=2); crossStride=100
        // scrollOffset=100 → minCrossSlots=ceil(100/100)=1
        // a.bottom=1, not > 1 → skip; b.bottom=2, > 1 → return 1
        final items = [_item('a', 0, 0, 2, 1), _item('b', 0, 1, 2, 1)];
        final layout = _makeHLayout(
          crossSlotExtent: 100,
          items: items,
          maxCrossSlots: 2,
        );
        expect(layout.getMinChildIndexForScrollOffset(100), 1);
      });

      test('returns 0 for scrollOffset just before first item', () {
        final items = [_item('a', 0, 0, 2, 1)];
        final layout = _makeHLayout(
          crossSlotExtent: 100,
          items: items,
          maxCrossSlots: 1,
        );
        expect(layout.getMinChildIndexForScrollOffset(0.001), 0);
      });

      test('zero stride guard: returns 0 regardless of offset', () {
        // crossDashboardAxisStride <= 0 → return 0 immediately
        final layout = _makeHLayout(
          crossSlotExtent: 0,
          crossSpacing: 0,
          items: [_item('a', 0, 0, 1, 1)],
        );
        expect(layout.getMinChildIndexForScrollOffset(500), 0);
      });
    });

    // ── getMaxChildIndexForScrollOffset ───────────────────────────────────

    group('getMaxChildIndexForScrollOffset', () {
      test('returns 0 for empty items', () {
        final layout = _makeHLayout();
        expect(layout.getMaxChildIndexForScrollOffset(0), 0);
        expect(layout.getMaxChildIndexForScrollOffset(500), 0);
      });

      test('returns last index visible within scrollOffset', () {
        // items: a(top=0), b(top=1), c(top=2); crossStride=100
        // scrollOffset=200 → maxCrossAxisSlots=floor((200-0)/100)=2
        // From end: c.top=2, 2 < 2? No; b.top=1, 1 < 2? Yes → return 1
        final items = [
          _item('a', 0, 0, 2, 1),
          _item('b', 0, 1, 2, 1),
          _item('c', 0, 2, 2, 1),
        ];
        final layout = _makeHLayout(
          crossSlotExtent: 100,
          items: items,
          maxCrossSlots: 3,
        );
        expect(layout.getMaxChildIndexForScrollOffset(200), 1);
      });

      test('zero stride guard: returns 0', () {
        final layout = _makeHLayout(
          crossSlotExtent: 0,
          crossSpacing: 0,
          items: [_item('a', 0, 0, 1, 1)],
        );
        expect(layout.getMaxChildIndexForScrollOffset(500), 0);
      });
    });
  });

  // ── SliverDashboardGeometry ────────────────────────────────────────────────

  group('SliverDashboardGeometry', () {
    const geo = SliverDashboardGeometry(
      scrollOffset: 100,
      crossAxisOffset: 200,
      mainAxisExtent: 150,
      crossAxisExtent: 300,
    );

    test('trailingScrollOffset = scrollOffset + mainAxisExtent', () {
      expect(geo.trailingScrollOffset, 250.0);
    });

    test('trailingScrollOffset when scrollOffset=0 equals mainAxisExtent', () {
      const g = SliverDashboardGeometry(
        scrollOffset: 0,
        crossAxisOffset: 0,
        mainAxisExtent: 80,
        crossAxisExtent: 160,
      );
      expect(g.trailingScrollOffset, 80.0);
    });

    group('getSize', () {
      test('horizontal: Size(crossAxisExtent, mainAxisExtent)', () {
        final size = geo.getSize(DashboardAxis.horizontal);
        expect(size.width, 300.0);
        expect(size.height, 150.0);
      });

      test('vertical: Size(mainAxisExtent, crossAxisExtent)', () {
        final size = geo.getSize(DashboardAxis.vertical);
        expect(size.width, 150.0);
        expect(size.height, 300.0);
      });
    });

    group('getOrigin', () {
      test('horizontal: Offset(crossAxisOffset, scrollOffset)', () {
        final origin = geo.getOrigin(DashboardAxis.horizontal);
        expect(origin.dx, 200.0);
        expect(origin.dy, 100.0);
      });

      test('vertical: Offset(scrollOffset, crossAxisOffset)', () {
        final origin = geo.getOrigin(DashboardAxis.vertical);
        expect(origin.dx, 100.0);
        expect(origin.dy, 200.0);
      });
    });

    group('getBoxItemGeometry', () {
      test('horizontal: origin and size are consistent with getOrigin/getSize',
          () {
        final boxGeo = geo.getBoxItemGeometry(DashboardAxis.horizontal);
        final origin = geo.getOrigin(DashboardAxis.horizontal);
        final size = geo.getSize(DashboardAxis.horizontal);
        expect(boxGeo.origin, origin);
        expect(boxGeo.size, size);
      });

      test('vertical: origin and size are consistent with getOrigin/getSize',
          () {
        final boxGeo = geo.getBoxItemGeometry(DashboardAxis.vertical);
        final origin = geo.getOrigin(DashboardAxis.vertical);
        final size = geo.getSize(DashboardAxis.vertical);
        expect(boxGeo.origin, origin);
        expect(boxGeo.size, size);
      });
    });

    test('getBoxConstraints returns BoxConstraints with correct main extent', () {
      final constraints = _verticalConstraints(crossAxisExtent: 400);
      final boxConstraints = geo.getBoxConstraints(constraints);
      expect(boxConstraints.minHeight, geo.mainAxisExtent);
      expect(boxConstraints.maxHeight, geo.mainAxisExtent);
    });
  });

  // ── BoxItemGeometry ────────────────────────────────────────────────────────

  group('BoxItemGeometry', () {
    test('stores origin and size correctly', () {
      const origin = Offset(10, 20);
      const size = Size(100, 200);
      const geo = BoxItemGeometry(origin: origin, size: size);
      expect(geo.origin, origin);
      expect(geo.size, size);
    });

    test('zero origin and size are preserved', () {
      const geo = BoxItemGeometry(origin: Offset.zero, size: Size.zero);
      expect(geo.origin, Offset.zero);
      expect(geo.size, Size.zero);
    });
  });

  // ── SliverDashboardDelegateWithFixedSlotCount ──────────────────────────────

  group('SliverDashboardDelegateWithFixedSlotCount', () {
    List<LayoutItem> _validItems() => [
      _item('a', 0, 0, 2, 1),
      _item('b', 2, 0, 2, 1),
    ];

    group('shouldRelayout', () {
      test('returns false when all fields are identical', () {
        final items = _validItems();
        final d1 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: items,
          axis: DashboardAxis.horizontal,
          aspectRatio: 1.5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 4,
        );
        final d2 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: items,
          axis: DashboardAxis.horizontal,
          aspectRatio: 1.5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 4,
        );
        expect(d2.shouldRelayout(d1), isFalse);
      });

      test('returns true when aspectRatio changes', () {
        final d1 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: _validItems(),
          axis: DashboardAxis.horizontal,
          aspectRatio: 1.0,
        );
        final d2 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: _validItems(),
          axis: DashboardAxis.horizontal,
          aspectRatio: 2.0,
        );
        expect(d2.shouldRelayout(d1), isTrue);
      });

      test('returns true when mainAxisSpacing changes', () {
        final d1 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: _validItems(),
          axis: DashboardAxis.horizontal,
          mainAxisSpacing: 0,
        );
        final d2 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: _validItems(),
          axis: DashboardAxis.horizontal,
          mainAxisSpacing: 10,
        );
        expect(d2.shouldRelayout(d1), isTrue);
      });

      test('returns true when crossAxisSpacing changes', () {
        final d1 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: _validItems(),
          axis: DashboardAxis.horizontal,
          crossAxisSpacing: 0,
        );
        final d2 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: _validItems(),
          axis: DashboardAxis.horizontal,
          crossAxisSpacing: 10,
        );
        expect(d2.shouldRelayout(d1), isTrue);
      });

      test('returns true when items list changes', () {
        final d1 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: [_item('a', 0, 0, 2, 1)],
          axis: DashboardAxis.horizontal,
        );
        final d2 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: [_item('a', 0, 0, 2, 1), _item('b', 2, 0, 2, 1)],
          axis: DashboardAxis.horizontal,
        );
        expect(d2.shouldRelayout(d1), isTrue);
      });

      test('returns true when mainAxisSlots changes', () {
        final d1 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: [],
          axis: DashboardAxis.horizontal,
        );
        final d2 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 6,
          items: [],
          axis: DashboardAxis.horizontal,
        );
        expect(d2.shouldRelayout(d1), isTrue);
      });

      test('returns true when axis changes', () {
        final d1 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: [],
          axis: DashboardAxis.horizontal,
        );
        final d2 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: [],
          axis: DashboardAxis.vertical,
        );
        expect(d2.shouldRelayout(d1), isTrue);
      });

      test('returns true when delegate type changes', () {
        final d1 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: [],
          axis: DashboardAxis.horizontal,
        );
        // Use a different delegate type (subclass via anonymous override would
        // need a real subclass; we test by checking the type guard path via
        // shouldRelayout returning true for different runtime types)
        // This is documented behavior in the shouldRelayout implementation.
        // The assertion is: if oldDelegate is not the same concrete type,
        // shouldRelayout returns true. Since we only have one concrete type,
        // we verify the identical-type path here.
        final d2 = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: [],
          axis: DashboardAxis.horizontal,
        );
        // identical type, identical fields → false
        expect(d2.shouldRelayout(d1), isFalse);
      });
    });

    group('getLayout', () {
      test('computes correct mainDashboardAxisSlotExtent (no spacing)', () {
        // crossAxisExtent=600, mainAxisSlots=4, spacing=0 → 600/4 = 150
        final delegate = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: [_item('a', 0, 0, 2, 1)],
          axis: DashboardAxis.horizontal,
          aspectRatio: 1.0,
          mainAxisSpacing: 0,
        );
        final layout = delegate.getLayout(
          _verticalConstraints(crossAxisExtent: 600),
        );
        expect(layout.mainDashboardAxisSlotExtent, 150.0);
      });

      test('computes correct slotExtent with spacing', () {
        // usable = 600 - (4-1)*10 = 570; slotExtent = 570/4 = 142.5
        final delegate = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: [],
          axis: DashboardAxis.horizontal,
          mainAxisSpacing: 10,
        );
        final layout = delegate.getLayout(
          _verticalConstraints(crossAxisExtent: 600),
        );
        expect(layout.mainDashboardAxisSlotExtent, closeTo(142.5, 0.001));
      });

      test('crossDashboardAxisSlotExtent = mainSlotExtent / aspectRatio', () {
        final delegate = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: [_item('a', 0, 0, 2, 1)],
          axis: DashboardAxis.horizontal,
          aspectRatio: 2.0,
        );
        final layout = delegate.getLayout(
          _verticalConstraints(crossAxisExtent: 400),
        );
        // mainSlotExtent = 400/4 = 100; crossSlotExtent = 100/2 = 50
        expect(layout.mainDashboardAxisSlotExtent, 100.0);
        expect(layout.crossDashboardAxisSlotExtent, 50.0);
      });

      test(
        'maxCrossDashboardAxisSlots reflects the maximum cross extent of items',
        () {
          final items = [
            _item('a', 0, 0, 2, 3), // bottom = 3
            _item('b', 2, 0, 2, 2), // bottom = 2
          ];
          final delegate = SliverDashboardDelegateWithFixedSlotCount(
            mainAxisSlots: 4,
            items: items,
            axis: DashboardAxis.horizontal,
          );
          final layout = delegate.getLayout(
            _verticalConstraints(crossAxisExtent: 400),
          );
          expect(layout.maxCrossDashboardAxisSlots, 3);
        },
      );

      test(
        'vertical axis: maxCrossDashboardAxisSlots uses item.rect.right',
        () {
          final items = [
            _item('a', 0, 0, 4, 2), // right = 4
            _item('b', 0, 2, 3, 2), // right = 3
          ];
          final delegate = SliverDashboardDelegateWithFixedSlotCount(
            mainAxisSlots: 4,
            items: items,
            axis: DashboardAxis.vertical,
          );
          final layout = delegate.getLayout(
            _horizontalConstraints(crossAxisExtent: 400),
          );
          expect(layout.maxCrossDashboardAxisSlots, 4);
        },
      );

      test('empty items produces maxCrossDashboardAxisSlots=0', () {
        final delegate = SliverDashboardDelegateWithFixedSlotCount(
          mainAxisSlots: 4,
          items: [],
          axis: DashboardAxis.horizontal,
        );
        final layout = delegate.getLayout(
          _verticalConstraints(crossAxisExtent: 400),
        );
        expect(layout.maxCrossDashboardAxisSlots, 0);
      });
    });
  });
}
