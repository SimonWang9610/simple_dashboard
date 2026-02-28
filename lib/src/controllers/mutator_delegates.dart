import 'package:collection/collection.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

enum DropStrategy {
  noCollision,
  reflow,
}

sealed class DashboardMutatorDelegate {
  const DashboardMutatorDelegate();

  List<LayoutItem>? adopt(
    LayoutRect rect,
    DragInfo dragInfo,
    List<LayoutItem> items,
  );
}

final class NoCollisionMutatorDelegate extends DashboardMutatorDelegate {
  const NoCollisionMutatorDelegate();

  @override
  List<LayoutItem>? adopt(
    LayoutRect rect,
    DragInfo dragInfo,
    List<LayoutItem> items,
  ) {
    final collisions = LayoutChecker.checkCollisions(
      items.where((i) => i.id is! PlaceholderId),
      rect,
    );

    if (collisions.hasCollision) {
      return null;
    }

    final placeholder = ItemPlaceholder(
      dragInfo.item.id,
      rect: rect,
    );

    return items.map((i) {
      if (i.id == placeholder.id) {
        return placeholder;
      }
      return i;
    }).toList();
  }
}

final class ReflowMutatorDelegate extends DashboardMutatorDelegate {
  final DashboardMetricsManager metrics;
  const ReflowMutatorDelegate(this.metrics);

  @override
  List<LayoutItem>? adopt(
    LayoutRect rect,
    DragInfo dragInfo,
    List<LayoutItem> items,
  ) {
    final noPlaceHolderItems = items.where((i) => i.id is! PlaceholderId);
    final collisions = LayoutChecker.checkCollisions(noPlaceHolderItems, rect);

    final placeholder = ItemPlaceholder(
      dragInfo.item.id,
      rect: rect,
    );

    if (!collisions.hasCollision) {
      return items.map((i) {
        if (i.id == placeholder.id) {
          return placeholder;
        }
        return i;
      }).toList();
    }

    final sorted = DashboardHelper.sort(noPlaceHolderItems, metrics.axis);

    final after = sorted.reversed
        .skipWhile((i) => i.id == dragInfo.item.id)
        .firstWhereOrNull((i) => i.rect.compare(rect, metrics.axis) < 0);

    final positioned = DashboardAfterPositioner(
      items: sorted,
      axis: metrics.axis,
      mainAxisSlots: metrics.mainAxisSlots,
      maxCrossSlots: metrics.maxCrossAxisSlots,
      afterId: after?.id,
      append: false,
    ).position(placeholder.id, placeholder.rect.size);

    final placeholderIndex = positioned.indexWhere(
      (i) => i.id == placeholder.id,
    );

    final newPlaceholder = placeholderIndex != -1
        ? positioned[placeholderIndex]
        : null;

    if (newPlaceholder == null) {
      return null;
    }

    positioned[placeholderIndex] = ItemPlaceholder(
      dragInfo.item.id,
      rect: newPlaceholder.rect,
    );

    return positioned;
  }
}

// TODO: implement ResizeMutatorDelegate
final class ResizeMutatorDelegate extends DashboardMutatorDelegate {
  final DashboardMetricsManager metrics;
  final ResizeDirection direction;
  final int dx;
  final int dy;

  const ResizeMutatorDelegate(
    this.metrics, {
    required this.direction,
    required this.dx,
    required this.dy,
  });

  @override
  List<LayoutItem>? adopt(
    LayoutRect rect,
    DragInfo dragInfo,
    List<LayoutItem> items,
  ) {
    final noPlaceHolderItems = items.where((i) => i.id is! ItemPlaceholder);
    final collisions = LayoutChecker.checkCollisions(noPlaceHolderItems, rect);

    final placeholder = ItemPlaceholder(
      dragInfo.item.id,
      rect: rect,
    );

    if (!collisions.hasCollision) {
      return items.map((i) {
        if (i.id == placeholder.id) {
          return placeholder;
        }
        return i;
      }).toList();
    }

    /// 1. collect all conflicted items along the resize direction
    /// 2. if any item cannot accept the resize delta, (e.g., cannot resize, not valid rect after resize),
    /// return null to indicate the resize is not allowed
    /// return null to indicate the resize is not allowed
    ///
    return null;
  }
}
