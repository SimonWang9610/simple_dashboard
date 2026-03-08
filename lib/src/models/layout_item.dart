import 'package:simple_dashboard/src/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:simple_dashboard/src/models/placeholder.dart';

class LayoutRect extends Equatable {
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

  bool isOverflow(DashboardAxis axis, int mainAxisSlots) {
    switch (axis) {
      case DashboardAxis.horizontal:
        return right > mainAxisSlots;
      case DashboardAxis.vertical:
        return bottom > mainAxisSlots;
    }
  }

  @override
  List<Object?> get props => [x, y, size];

  @override
  String toString() {
    return "LayoutRect(x: $x, y: $y, width: ${size.width}, height: ${size.height})";
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

class LayoutItem extends Equatable {
  final Object id;
  final LayoutRect rect;
  final LayoutSize minSize;
  final LayoutSize? maxSize;

  LayoutItem({
    required this.id,
    required this.rect,
    this.minSize = const LayoutSize(width: 1, height: 1),
    this.maxSize,
  }) : assert(
         rect.size.width >= minSize.width && rect.size.height >= minSize.height,
         "The minimum size of a layout item cannot be larger than its current size.",
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

  bool canAcceptSize(LayoutSize newSize) {
    if (newSize.width < minSize.width || newSize.height < minSize.height) {
      return false;
    }

    if (maxSize != null) {
      if (newSize.width > maxSize!.width || newSize.height > maxSize!.height) {
        return false;
      }
    }

    return true;
  }

  factory LayoutItem.placeholderOf(LayoutItem item, {LayoutRect? newRect}) {
    return LayoutItem(
      id: PlaceholderId(item.id),
      rect: newRect ?? item.rect,
      minSize: item.minSize,
      maxSize: item.maxSize,
    );
  }

  bool isPlaceholderOf(Object otherId) {
    return id is PlaceholderId && (id as PlaceholderId).itemId == otherId;
  }

  bool get isPlaceholder => id is PlaceholderId;

  @override
  List<Object?> get props => [id, rect, minSize, maxSize];

  LayoutItem get originalItem {
    if (id is PlaceholderId) {
      return LayoutItem(
        id: (id as PlaceholderId).itemId,
        rect: rect,
        minSize: minSize,
        maxSize: maxSize,
      );
    } else {
      return this;
    }
  }
}
