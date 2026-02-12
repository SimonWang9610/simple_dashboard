import 'package:simple_dashboard/simple_dashboard.dart';

class LayoutCollisionResult {
  final LayoutRect rect;
  final List<LayoutItem> topLeft;
  final List<LayoutItem> topRight;
  final List<LayoutItem> bottomLeft;
  final List<LayoutItem> bottomRight;

  const LayoutCollisionResult({
    required this.rect,
    this.topLeft = const [],
    this.topRight = const [],
    this.bottomLeft = const [],
    this.bottomRight = const [],
  });

  bool get hasCollision {
    return topLeft.isNotEmpty ||
        topRight.isNotEmpty ||
        bottomLeft.isNotEmpty ||
        bottomRight.isNotEmpty;
  }

  bool get hasRightCollision {
    return topRight.isNotEmpty || bottomRight.isNotEmpty;
  }

  bool get hasLeftCollision {
    return topLeft.isNotEmpty || bottomLeft.isNotEmpty;
  }

  bool get hasTopCollision {
    return topLeft.isNotEmpty || topRight.isNotEmpty;
  }

  bool get hasBottomCollision {
    return bottomLeft.isNotEmpty || bottomRight.isNotEmpty;
  }
}
