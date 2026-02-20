import 'package:flutter/rendering.dart';
import 'package:simple_dashboard/src/models/dashboard_layout_item.dart';

mixin DashboardPlaceholderMixin on RenderBox {
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
