import 'dart:async';

import 'package:flutter/material.dart';

class AutoScrollController {
  final double edgeThreshold;
  final double speed;

  AutoScrollController({
    required this.edgeThreshold,
    required this.speed,
  });

  Timer? _autoScrollTimer;
  double? _scrollUnit;

  void start(BuildContext context, Offset localPosition) {
    final scrollable = Scrollable.maybeOf(context);
    final scrollableSize = scrollable?.context.size;

    final itemCenter = context.size?.center(Offset.zero);

    if (scrollable == null || scrollableSize == null || itemCenter == null) {
      stop();
      return;
    }

    final viewportSize = scrollableSize;
    final scrollDirection = scrollable.axisDirection;

    double? scrollUnit;

    switch (scrollDirection) {
      case AxisDirection.up:
        if (localPosition.dy < edgeThreshold) {
          scrollUnit = 1.0;
        } else if (localPosition.dy > viewportSize.height - edgeThreshold) {
          scrollUnit = -1.0;
        }
        break;
      case AxisDirection.down:
        if (localPosition.dy < edgeThreshold) {
          scrollUnit = -1.0;
        } else if (localPosition.dy > viewportSize.height - edgeThreshold) {
          scrollUnit = 1.0;
        }
        break;
      case AxisDirection.left:
        if (localPosition.dx < edgeThreshold) {
          scrollUnit = -1.0;
        } else if (localPosition.dx > viewportSize.width - edgeThreshold) {
          scrollUnit = 1.0;
        }
        break;
      case AxisDirection.right:
        if (localPosition.dx < edgeThreshold) {
          scrollUnit = -1.0;
        } else if (localPosition.dx > viewportSize.width - edgeThreshold) {
          scrollUnit = 1.0;
        }
        break;
    }

    print(
      "localPosition: $localPosition, scrollUnit: $scrollUnit",
    ); // Debug print

    if (scrollUnit == null) {
      stop();
      return;
    }

    final position = scrollable.position;

    _start(position, scrollUnit);
  }

  void _start(ScrollPosition position, double scrollUnit) {
    if (_scrollUnit == scrollUnit &&
        _autoScrollTimer != null &&
        _autoScrollTimer!.isActive) {
      return;
    }

    _autoScrollTimer?.cancel();
    _scrollUnit = scrollUnit;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      final target = (position.pixels + _scrollUnit! * speed).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      position.jumpTo(target);
    });
  }

  void stop() {
    _scrollUnit = null;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }
}
