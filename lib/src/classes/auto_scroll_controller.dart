import 'dart:async';

import 'package:flutter/material.dart';

// class AutoScrollController {
//   final double edgeThreshold;
//   final double speed;

//   AutoScrollController({
//     required this.edgeThreshold,
//     required this.speed,
//   });

//   Timer? _autoScrollTimer;
//   double? _scrollUnit;

//   void start(BuildContext context, Offset localPosition) {
//     final scrollable = Scrollable.maybeOf(context);
//     final scrollableSize = scrollable?.context.size;

//     final itemCenter = context.size?.center(Offset.zero);

//     if (scrollable == null || scrollableSize == null || itemCenter == null) {
//       stop();
//       return;
//     }

//     final viewportSize = scrollableSize;
//     final scrollDirection = scrollable.axisDirection;

//     double? scrollUnit;

//     switch (scrollDirection) {
//       case AxisDirection.up:
//         if (localPosition.dy < edgeThreshold) {
//           scrollUnit = 1.0;
//         } else if (localPosition.dy > viewportSize.height - edgeThreshold) {
//           scrollUnit = -1.0;
//         }
//         break;
//       case AxisDirection.down:
//         if (localPosition.dy < edgeThreshold) {
//           scrollUnit = -1.0;
//         } else if (localPosition.dy > viewportSize.height - edgeThreshold) {
//           scrollUnit = 1.0;
//         }
//         break;
//       case AxisDirection.left:
//         if (localPosition.dx < edgeThreshold) {
//           scrollUnit = -1.0;
//         } else if (localPosition.dx > viewportSize.width - edgeThreshold) {
//           scrollUnit = 1.0;
//         }
//         break;
//       case AxisDirection.right:
//         if (localPosition.dx < edgeThreshold) {
//           scrollUnit = -1.0;
//         } else if (localPosition.dx > viewportSize.width - edgeThreshold) {
//           scrollUnit = 1.0;
//         }
//         break;
//     }

//     print(
//       "localPosition: $localPosition, scrollUnit: $scrollUnit",
//     ); // Debug print

//     if (scrollUnit == null) {
//       stop();
//       return;
//     }

//     final position = scrollable.position;

//     _start(position, scrollUnit);
//   }

//   void _start(ScrollPosition position, double scrollUnit) {
//     if (_scrollUnit == scrollUnit &&
//         _autoScrollTimer != null &&
//         _autoScrollTimer!.isActive) {
//       return;
//     }

//     _autoScrollTimer?.cancel();
//     _scrollUnit = scrollUnit;

//     _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
//       timer,
//     ) {
//       final target = (position.pixels + _scrollUnit! * speed).clamp(
//         position.minScrollExtent,
//         position.maxScrollExtent,
//       );
//       position.jumpTo(target);
//     });
//   }

//   void stop() {
//     _scrollUnit = null;
//     _autoScrollTimer?.cancel();
//     _autoScrollTimer = null;
//   }
// }

sealed class AutoScroll {
  final double edgeThreshold;
  final double speed;
  final AxisDirection direction;

  AutoScroll({
    required this.edgeThreshold,
    required this.speed,
    required this.direction,
  });

  void start(
    Size viewportSize,
    Offset currentPointerPosition,
  ) {
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

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
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
    required super.edgeThreshold,
    required super.speed,
    required super.direction,
  });

  @override
  ScrollPosition get scrollPosition => controller.position;
}
