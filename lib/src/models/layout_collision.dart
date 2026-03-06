import 'package:simple_dashboard/simple_dashboard.dart';

class LayoutCollisionResult {
  final LayoutRect rect;
  final Map<CollisionDirection, List<LayoutItem>> _collisions;

  const LayoutCollisionResult({
    required this.rect,
    Map<CollisionDirection, List<LayoutItem>> collisions = const {},
  }) : _collisions = collisions;

  bool get hasCollision {
    return _collisions.values.any((list) => list.isNotEmpty);
  }

  List<LayoutItem> operator [](CollisionDirection direction) {
    return _collisions[direction] ?? [];
  }

  List<LayoutItem> get collisions {
    return _collisions.values.expand((list) => list).toList();
  }
}

enum CollisionDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}
