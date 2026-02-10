import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';
import 'package:simple_dashboard/src/widgets/controller.dart';

class DashboardItemParentData extends ContainerBoxParentData<RenderBox> {
  ItemRect? rect;
}

class RenderDashboard extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, DashboardItemParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, DashboardItemParentData> {
  RenderDashboard({
    List<RenderBox>? children,
    required DashboardLayoutNotifier layoutNotifier,
  }) : _layoutNotifier = layoutNotifier {
    addAll(children);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _layoutNotifier.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _layoutNotifier.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void setupParentData(covariant RenderObject child) {
    super.setupParentData(child);

    if (child.parentData is! DashboardItemParentData) {
      child.parentData = DashboardItemParentData();
    }
  }

  DashboardLayoutNotifier _layoutNotifier;
  set layoutNotifier(DashboardLayoutNotifier value) {
    if (_layoutNotifier == value) return;
    if (attached) {
      _layoutNotifier.removeListener(markNeedsLayout);
    }
    _layoutNotifier = value;

    if (attached) {
      _layoutNotifier.addListener(markNeedsLayout);
    }

    markNeedsLayout();
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.smallest;
      return;
    }

    final pixelsPerFlex = this.pixelsPerFlex;

    RenderBox? child = firstChild;

    final mainAxisExtent = _layoutNotifier.axis == DashboardAxis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;

    double crossAxisExtent = 0;

    while (child != null) {
      final childParentData = child.parentData as DashboardItemParentData;

      assert(
        childParentData.rect != null,
        "Each child of Dashboard must have a non-null rect in its parent data, use DashboardItemDataWidget to set the rect for each child.",
      );

      final rect = childParentData.rect!;

      child.layout(
        BoxConstraints.tight(rect.flexes & pixelsPerFlex),
        parentUsesSize: true,
      );

      childParentData.offset = rect.toOffset(
        pixelsPerFlex,
        hSpacing: _layoutNotifier.horizontalSpacing,
        vSpacing: _layoutNotifier.verticalSpacing,
      );

      final uiRect = childParentData.offset & child.size;

      crossAxisExtent = math.max(
        crossAxisExtent,
        _layoutNotifier.axis == DashboardAxis.horizontal
            ? uiRect.bottom
            : uiRect.right,
      );

      child = childParentData.nextSibling;
    }

    size = Size(
      _layoutNotifier.axis == DashboardAxis.horizontal
          ? mainAxisExtent
          : crossAxisExtent,
      _layoutNotifier.axis == DashboardAxis.horizontal
          ? crossAxisExtent
          : mainAxisExtent,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  double get pixelsPerFlex {
    assert(
      () {
        if (_layoutNotifier.axis == DashboardAxis.horizontal) {
          return constraints.maxWidth.isFinite;
        } else {
          return constraints.maxHeight.isFinite;
        }
      }(),
      "Given infinite main axis constraints, pixels per flex cannot be calculated.",
    );

    final mainAxisExtent = _layoutNotifier.axis == DashboardAxis.horizontal
        ? constraints.maxWidth -
              (_layoutNotifier.mainAxisFlexCount - 1) *
                  _layoutNotifier.mainAxisSpacing
        : constraints.maxHeight -
              (_layoutNotifier.mainAxisFlexCount - 1) *
                  _layoutNotifier.mainAxisSpacing;

    return mainAxisExtent / _layoutNotifier.mainAxisFlexCount;
  }
}
