import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:simple_dashboard/src/sliver/models.dart';

import 'delegates.dart';

class SliverDashboardParentData extends SliverMultiBoxAdaptorParentData {
  double? crossAxisOffset;
}

class RenderSliverDashboard extends RenderSliverMultiBoxAdaptor {
  RenderSliverDashboard({
    required super.childManager,
    required SliverDashboardDelegate layoutDelegate,
  }) : _layoutDelegate = layoutDelegate;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverDashboardParentData) {
      child.parentData = SliverDashboardParentData();
    }
  }

  SliverDashboardDelegate _layoutDelegate;
  set layoutDelegate(SliverDashboardDelegate value) {
    if (_layoutDelegate == value) return;

    if (value.runtimeType != _layoutDelegate.runtimeType ||
        value.shouldRelayout(_layoutDelegate)) {
      markNeedsLayout();
    }

    _layoutDelegate = value;
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    final dashboardLayout = _layoutDelegate.getLayout(constraints);

    final firstIndex = dashboardLayout.getMinChildIndexForScrollOffset(
      scrollOffset,
    );

    final targetLastIndex = targetEndScrollOffset.isFinite
        ? dashboardLayout.getMaxChildIndexForScrollOffset(targetEndScrollOffset)
        : 0;

    if (firstChild != null) {
      final int leadingGarbage = calculateLeadingGarbage(
        firstIndex: firstIndex,
      );
      final int trailingGarbage = targetLastIndex != null
          ? calculateTrailingGarbage(lastIndex: targetLastIndex)
          : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    final firstChildGeometry = dashboardLayout.computeItemGeometry(firstIndex);

    if (firstChild == null) {
      if (!addInitialChild(
        index: firstIndex,
        layoutOffset: firstChildGeometry.scrollOffset,
      )) {
        // There are either no children, or we are past the end of all our children.
        final double max = dashboardLayout.computeMaxScrollOffset();

        geometry = SliverGeometry(scrollExtent: max, maxPaintExtent: max);
        childManager.didFinishLayout();
        return;
      }
    }

    final double leadingScrollOffset = firstChildGeometry.scrollOffset;
    double trailingScrollOffset = firstChildGeometry.trailingScrollOffset;
    RenderBox? trailingChildWithLayout;
    bool reachedEnd = false;

    for (int index = indexOf(firstChild!) - 1; index >= firstIndex; --index) {
      final geometry = dashboardLayout.computeItemGeometry(index);
      final RenderBox child = insertAndLayoutLeadingChild(
        geometry.getBoxConstraints(constraints),
      )!;

      _setupChildParentData(child, geometry, index);

      trailingChildWithLayout ??= child;
      trailingScrollOffset = math.max(
        trailingScrollOffset,
        geometry.trailingScrollOffset,
      );
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(firstChildGeometry.getBoxConstraints(constraints));
      _setupChildParentData(firstChild!, firstChildGeometry, firstIndex);
      trailingChildWithLayout = firstChild;
    }

    for (
      int index = indexOf(trailingChildWithLayout!) + 1;
      targetLastIndex == null || index <= targetLastIndex;
      ++index
    ) {
      final geometry = dashboardLayout.computeItemGeometry(index);

      final BoxConstraints childConstraints = geometry.getBoxConstraints(
        constraints,
      );

      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(
          childConstraints,
          after: trailingChildWithLayout,
        );
        if (child == null) {
          reachedEnd = true;
          // We have run out of children.
          break;
        }
      } else {
        child.layout(childConstraints);
      }
      trailingChildWithLayout = child;

      _setupChildParentData(child, geometry, index);

      trailingScrollOffset = math.max(
        trailingScrollOffset,
        geometry.trailingScrollOffset,
      );
    }

    final int lastIndex = indexOf(lastChild!);

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild!) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    final double estimatedTotalExtent = reachedEnd
        ? trailingScrollOffset
        : dashboardLayout.computeMaxScrollOffset();

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: math.min(constraints.scrollOffset, leadingScrollOffset),
      to: trailingScrollOffset,
    );

    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    geometry = SliverGeometry(
      scrollExtent: estimatedTotalExtent,
      paintExtent: paintExtent > estimatedTotalExtent
          ? estimatedTotalExtent
          : paintExtent,
      maxPaintExtent: estimatedTotalExtent,
      cacheExtent: cacheExtent,
      hasVisualOverflow:
          estimatedTotalExtent > paintExtent ||
          constraints.scrollOffset > 0.0 ||
          constraints.overlap != 0.0,
    );

    // We may have started the layout while scrolled to the end, which
    // would not expose a new child.
    if (estimatedTotalExtent == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }

  void _setupChildParentData(
    RenderBox child,
    SliverDashboardGeometry geometry,
    int index,
  ) {
    final SliverDashboardParentData childParentData =
        child.parentData! as SliverDashboardParentData;
    childParentData.layoutOffset = geometry.scrollOffset;
    childParentData.crossAxisOffset = geometry.crossAxisOffset;

    assert(childParentData.index == index);
  }

  @override
  double childCrossAxisPosition(RenderBox child) {
    final SliverDashboardParentData childParentData =
        child.parentData! as SliverDashboardParentData;
    return childParentData.crossAxisOffset ?? 0.0;
  }
}
