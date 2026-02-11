import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_delegate.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/models/enums.dart';

class DashboardItemParentData extends ContainerBoxParentData<RenderBox> {
  LayoutItem? layout;
}

class RenderDashboard extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, DashboardItemParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, DashboardItemParentData> {
  RenderDashboard({
    List<RenderBox>? children,
    required DashboardLayoutDelegate layoutDelegate,
    required DashboardAxis axis,
    required int mainAxisSlots,
  }) : _delegate = layoutDelegate,
       _axis = axis,
       _mainAxisSlots = mainAxisSlots {
    addAll(children);
  }

  @override
  void setupParentData(covariant RenderObject child) {
    super.setupParentData(child);

    if (child.parentData is! DashboardItemParentData) {
      child.parentData = DashboardItemParentData();
    }
  }

  DashboardLayoutDelegate _delegate;
  set layoutDelegate(DashboardLayoutDelegate value) {
    if (_delegate != value) {
      final oldDelegate = _delegate;
      _delegate = value;
      if (value.shouldRelayout(oldDelegate)) {
        markNeedsLayout();
      }
    }
  }

  int _mainAxisSlots;
  set mainAxisSlots(int value) {
    if (_mainAxisSlots != value) {
      _mainAxisSlots = value;
      markNeedsLayout();
    }
  }

  DashboardAxis _axis;
  set axis(DashboardAxis value) {
    if (_axis != value) {
      _axis = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.smallest;
      return;
    }

    final extents = _delegate.computeLayoutExtentUnit(
      constraints,
      _axis,
      _mainAxisSlots,
    );

    RenderBox? child = firstChild;

    final mainAxisExtent = _axis == DashboardAxis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;

    double crossAxisExtent = 0;

    while (child != null) {
      final childParentData = child.parentData as DashboardItemParentData;

      assert(childParentData.layout != null);

      final rect = _delegate.computeItemRect(
        childParentData.layout!.rect,
        extents,
      );

      child.layout(
        BoxConstraints.tight(rect.size),
        parentUsesSize: true,
      );

      childParentData.offset = rect.topLeft;

      crossAxisExtent = math.max(
        crossAxisExtent,
        _axis == DashboardAxis.horizontal ? rect.bottom : rect.right,
      );

      child = childParentData.nextSibling;
    }

    size = Size(
      _axis == DashboardAxis.horizontal ? mainAxisExtent : crossAxisExtent,
      _axis == DashboardAxis.horizontal ? crossAxisExtent : mainAxisExtent,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
