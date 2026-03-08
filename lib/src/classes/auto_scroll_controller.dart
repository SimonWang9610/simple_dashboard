import 'dart:async';

import 'package:flutter/material.dart';

sealed class AutoScroll {
  final double speed;
  final AxisDirection direction;

  AutoScroll({
    required this.speed,
    required this.direction,
  });

  void start(
    Size viewportSize,
    Offset currentPointerPosition, {
    double edgeThreshold = 50.0,
  }) {
    double? scrollUnit;

    switch (direction) {
      case AxisDirection.up:
        if (currentPointerPosition.dy < edgeThreshold) {
          scrollUnit = 1.0;
        } else if (currentPointerPosition.dy >
            viewportSize.height - edgeThreshold) {
          scrollUnit = -1.0;
        }
        break;
      case AxisDirection.down:
        if (currentPointerPosition.dy < edgeThreshold) {
          scrollUnit = -1.0;
        } else if (currentPointerPosition.dy >
            viewportSize.height - edgeThreshold) {
          scrollUnit = 1.0;
        }
        break;
      case AxisDirection.left:
        if (currentPointerPosition.dx < edgeThreshold) {
          scrollUnit = -1.0;
        } else if (currentPointerPosition.dx >
            viewportSize.width - edgeThreshold) {
          scrollUnit = 1.0;
        }
        break;
      case AxisDirection.right:
        if (currentPointerPosition.dx < edgeThreshold) {
          scrollUnit = -1.0;
        } else if (currentPointerPosition.dx >
            viewportSize.width - edgeThreshold) {
          scrollUnit = 1.0;
        }
        break;
    }

    if (scrollUnit == null) {
      stop();
      return;
    }

    _start(scrollUnit);
  }

  void stop() {
    _scrollUnit = null;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  ScrollPosition get scrollPosition;

  Timer? _autoScrollTimer;
  double? _scrollUnit;

  void _start(double scrollUnit) {
    if (_scrollUnit == scrollUnit &&
        _autoScrollTimer != null &&
        _autoScrollTimer!.isActive) {
      return;
    }

    _autoScrollTimer?.cancel();
    _scrollUnit = scrollUnit;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 17), (
      timer,
    ) {
      final target = (scrollPosition.pixels + _scrollUnit! * speed).clamp(
        scrollPosition.minScrollExtent,
        scrollPosition.maxScrollExtent,
      );
      scrollPosition.jumpTo(target);
    });
  }
}

final class AutoScrollWithController extends AutoScroll {
  final ScrollController controller;

  AutoScrollWithController({
    required this.controller,
    required super.speed,
    required super.direction,
  });

  @override
  ScrollPosition get scrollPosition => controller.position;
}
