import 'package:equatable/equatable.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';
import 'package:simple_dashboard/src/utils/extensions.dart';

class ItemCoordinate extends Equatable {
  /// The x coordinate of the item.
  /// This determines the horizontal position of the item in the dashboard.
  ///
  /// Unit same as [DashboardItem] flexes.
  final int x;

  /// The y coordinate of the item.
  /// This determines the vertical position of the item in the dashboard.
  final int y;

  const ItemCoordinate(this.x, this.y);

  ItemCoordinate move({
    int? x,
    int? y,
    int? maxX,
    int? maxY,
  }) {
    if (x == null && y == null) {
      return this;
    }

    final newX = this.x + (x ?? 0);
    final newY = this.y + (y ?? 0);

    return ItemCoordinate(
      newX.clampInt(0, maxX ?? newX),
      newY.clampInt(0, maxY ?? newY),
    );
  }

  @override
  List<Object?> get props => [x, y];
}

class ItemRect extends Equatable {
  final ItemCoordinate coordinate;
  final ItemFlex flexes;

  const ItemRect(this.coordinate, this.flexes);

  int get left => coordinate.x;
  int get right => coordinate.x + flexes.horizontal;
  int get top => coordinate.y;
  int get bottom => coordinate.y + flexes.vertical;

  ItemRect move({
    int? x,
    int? y,
    int? maxX,
    int? maxY,
  }) {
    return ItemRect(
      coordinate.move(
        x: x,
        y: y,
        maxX: maxX,
        maxY: maxY,
      ),
      flexes,
    );
  }

  ItemRect resize({
    required ItemFlexRange range,
    int? hStep,
    int? vStep,
  }) {
    return ItemRect(
      coordinate,
      range.resize(
        flexes,
        hStep: hStep,
        vStep: vStep,
      ),
    );
  }

  bool isOverlapped(ItemRect other) {
    return !(right <= other.left ||
        left >= other.right ||
        bottom <= other.top ||
        top >= other.bottom);
  }

  bool contains(ItemCoordinate coordinate) {
    return coordinate.x > left &&
        coordinate.x < right &&
        coordinate.y > top &&
        coordinate.y < bottom;
  }

  @override
  List<Object?> get props => [coordinate, flexes];
}
