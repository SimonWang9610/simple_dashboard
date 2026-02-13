import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_delegate.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';
import 'package:simple_dashboard/src/models/enums.dart';

class DashboardItemParentData extends ContainerBoxParentData<RenderBox> {
  LayoutRect? layout;
}

class RenderDashboard extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, DashboardItemParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, DashboardItemParentData>,
        DebugOverflowIndicatorMixin,
        _DashboardPlaceholderMixin {
  RenderDashboard({
    List<RenderBox>? children,
    required DashboardLayoutDelegate layoutDelegate,
    required DashboardAxis axis,
    required int mainAxisSlots,
    required ImageConfiguration imageConfiguration,
    LayoutPlaceholder? placeholder,
    BoxDecoration? placeholderDecoration,
  }) : _delegate = layoutDelegate,
       _axis = axis,
       _mainAxisSlots = mainAxisSlots {
    _placeholder = placeholder;
    _placeholderDecoration = placeholderDecoration;
    _imageConfiguration = imageConfiguration;
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

  _Overflow? _overflow;

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
    double maxMainAxisExtent = 0;

    while (child != null) {
      final childParentData = child.parentData as DashboardItemParentData;

      assert(childParentData.layout != null);

      final rect = _delegate.computeItemRect(
        childParentData.layout!,
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

      maxMainAxisExtent = math.max(
        maxMainAxisExtent,
        _axis == DashboardAxis.horizontal ? rect.right : rect.bottom,
      );

      child = childParentData.nextSibling;
    }

    _overflow = _Overflow(
      mainAxisOverflow: maxMainAxisExtent > mainAxisExtent
          ? maxMainAxisExtent - mainAxisExtent
          : null,
      crossAxisOverflow: switch (_axis) {
        DashboardAxis.horizontal =>
          constraints.hasBoundedHeight &&
                  crossAxisExtent > constraints.maxHeight
              ? crossAxisExtent - constraints.maxHeight
              : null,
        DashboardAxis.vertical =>
          constraints.hasBoundedWidth && crossAxisExtent > constraints.maxWidth
              ? crossAxisExtent - constraints.maxWidth
              : null,
      },
    );

    if (_placeholder != null) {
      _placeholderRect = _delegate.computeItemRect(
        _placeholder!.rect,
        extents,
      );
    }

    size = Size(
      _axis == DashboardAxis.horizontal ? mainAxisExtent : crossAxisExtent,
      _axis == DashboardAxis.horizontal ? crossAxisExtent : mainAxisExtent,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    paintPlaceholder(context, offset);

    defaultPaint(context, offset);

    if (_overflow == null || !_overflow!.hasOverflow) {
      return;
    }

    debugPrint(
      'Dashboard overflow detected: mainAxisOverflow=${_overflow!.mainAxisOverflow}, crossAxisOverflow=${_overflow!.crossAxisOverflow}',
    );

    assert(() {
      if (_overflow?.hasMainAxisOverflow ?? false) {
        final rect = switch (_axis) {
          DashboardAxis.horizontal => Rect.fromLTWH(
            0,
            0,
            size.width + _overflow!.mainAxisOverflow!,
            0,
          ),
          DashboardAxis.vertical => Rect.fromLTWH(
            0,
            0,
            0,
            size.height + _overflow!.mainAxisOverflow!,
          ),
        };
        paintOverflowIndicator(
          context,
          offset,
          Offset.zero & size,
          rect,
        );
      }

      if (_overflow?.hasCrossAxisOverflow ?? false) {
        final rect = switch (_axis) {
          DashboardAxis.horizontal => Rect.fromLTWH(
            0,
            0,
            0,
            size.height + _overflow!.crossAxisOverflow!,
          ),
          DashboardAxis.vertical => Rect.fromLTWH(
            0,
            0,
            size.width + _overflow!.crossAxisOverflow!,
            0,
          ),
        };
        paintOverflowIndicator(
          context,
          offset,
          Offset.zero & size,
          rect,
        );
      }
      return true;
    }());
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

class _Overflow {
  double? mainAxisOverflow;
  double? crossAxisOverflow;

  _Overflow({
    this.mainAxisOverflow,
    this.crossAxisOverflow,
  });

  bool get hasOverflow => hasMainAxisOverflow || hasCrossAxisOverflow;

  bool get hasMainAxisOverflow =>
      mainAxisOverflow != null && mainAxisOverflow! >= 1;
  bool get hasCrossAxisOverflow =>
      crossAxisOverflow != null && crossAxisOverflow! >= 1;
}

mixin _DashboardPlaceholderMixin on RenderBox {
  LayoutPlaceholder? _placeholder;

  set placeholder(LayoutPlaceholder? value) {
    if (_placeholder != value) {
      _placeholder = value;
      markNeedsLayout();
    }
  }

  BoxDecoration? _placeholderDecoration;
  set placeholderDecoration(BoxDecoration? value) {
    if (_placeholderDecoration != value) {
      _placeholderDecoration = value;
      markNeedsPaint();
    }
  }

  ImageConfiguration get imageConfiguration => _imageConfiguration;
  late ImageConfiguration _imageConfiguration;
  set imageConfiguration(ImageConfiguration value) {
    if (value == _imageConfiguration) {
      return;
    }
    _imageConfiguration = value;
    markNeedsPaint();
  }

  Rect? _placeholderRect;

  void paintPlaceholder(PaintingContext context, Offset offset) {
    if (_placeholder == null ||
        _placeholderDecoration == null ||
        _placeholderRect == null) {
      return;
    }

    final boxPainter = _placeholderDecoration!.createBoxPainter(markNeedsPaint);

    boxPainter.paint(
      context.canvas,
      offset + _placeholderRect!.topLeft,
      _imageConfiguration.copyWith(size: _placeholderRect!.size),
    );

    if (_placeholderDecoration?.isComplex ?? false) {
      context.setIsComplexHint();
    }
  }
}
