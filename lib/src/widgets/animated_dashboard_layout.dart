import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

class AnimatedDashboardLayout extends ImplicitlyAnimatedWidget {
  final LayoutRect rect;
  final Widget child;

  const AnimatedDashboardLayout({
    super.key,
    required this.rect,
    required this.child,
    super.duration = const Duration(milliseconds: 160),
    super.curve,
  });

  @override
  AnimatedWidgetBaseState<AnimatedDashboardLayout> createState() =>
      _AnimatedDashboardLayoutState();
}

class _AnimatedDashboardLayoutState
    extends AnimatedWidgetBaseState<AnimatedDashboardLayout> {
  LayoutRectTween? _rectTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _rectTween =
        visitor(
              _rectTween,
              widget.rect,
              (dynamic value) => LayoutRectTween(begin: value as LayoutRect),
            )
            as LayoutRectTween?;
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError("AnimatedDashboardLayout is not implemented yet.");
  }
}

class LayoutRectTween extends Tween<LayoutRect> {
  LayoutRectTween({super.begin, super.end});

  @override
  LayoutRect lerp(double t) {
    final position = _lerpPosition(t);

    return LayoutRect(
      x: position.$1,
      y: position.$2,
      size: end!.size,
    );
  }

  (int, int) _lerpPosition(double t) {
    if (t == 1.0) {
      return (end!.x, end!.y);
    } else if (t == 0.0) {
      return (begin!.x, begin!.y);
    }

    final x = (begin!.x + (end!.x - begin!.x) * t).round();
    final y = (begin!.y + (end!.y - begin!.y) * t).round();

    return (x, y);
  }
}
