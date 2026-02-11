import 'package:simple_dashboard/src/models/enums.dart';
import 'package:equatable/equatable.dart';

class LayoutRect {
  final int x;
  final int y;
  final LayoutSize size;

  const LayoutRect({
    required this.x,
    required this.y,
    required this.size,
  });

  int get left => x;
  int get right => x + size.width;
  int get top => y;
  int get bottom => y + size.height;

  int compare(LayoutRect other, DashboardAxis axis) {
    switch (axis) {
      case DashboardAxis.horizontal:
        if (y < other.y) {
          return -1;
        } else if (y == other.y) {
          return x - other.x;
        } else {
          return 1;
        }
      case DashboardAxis.vertical:
        if (x < other.x) {
          return -1;
        } else if (x == other.x) {
          return y - other.y;
        } else {
          return 1;
        }
    }
  }

  bool hasConflicts(LayoutRect other) {
    return !(right <= other.left ||
        left >= other.right ||
        bottom <= other.top ||
        top >= other.bottom);
  }
}

class LayoutSize extends Equatable {
  final int width;
  final int height;

  const LayoutSize({
    required this.width,
    required this.height,
  });

  LayoutSize constrain(DashboardAxis axis, int mainAxisSlots) {
    switch (axis) {
      case DashboardAxis.horizontal:
        return LayoutSize(
          width: width.clamp(1, mainAxisSlots),
          height: height,
        );
      case DashboardAxis.vertical:
        return LayoutSize(
          width: width,
          height: height.clamp(1, mainAxisSlots),
        );
    }
  }

  @override
  List<Object?> get props => [width, height];
}

class LayoutItem {
  final Object id;
  final LayoutRect rect;
  final LayoutSize? minSize;
  final LayoutSize? maxSize;

  LayoutItem({
    required this.id,
    required this.rect,
    this.minSize,
    this.maxSize,
  }) : assert(
         minSize == null ||
             (minSize.width <= rect.size.width &&
                 minSize.height <= rect.size.height),
         "The minimum size of a layout item cannot be greater than its current size.",
       ),
       assert(
         maxSize == null ||
             (maxSize.width >= rect.size.width &&
                 maxSize.height >= rect.size.height),
         "The maximum size of a layout item cannot be smaller than its current size.",
       );

  factory LayoutItem.fromCoordinate(
    String id, {
    required int x,
    required int y,
    required LayoutSize size,
  }) {
    return LayoutItem(
      id: id,
      rect: LayoutRect(x: x, y: y, size: size),
    );
  }

  LayoutPlaceholder get placeholder {
    return LayoutPlaceholder._(
      itemId: id,
      rect: rect,
    );
  }
}

final class LayoutPlaceholder extends LayoutItem {
  LayoutPlaceholder._({
    required Object itemId,
    required super.rect,
  }) : super(id: "$itemId-placeholder");
}
