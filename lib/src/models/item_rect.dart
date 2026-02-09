import 'package:equatable/equatable.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';

class ItemCoordinate extends Equatable {
  /// The x coordinate of the item.
  /// This determines the horizontal position of the item in the dashboard.
  ///
  /// Unit same as [DashboardItem] flexes.
  final int h;

  /// The y coordinate of the item.
  /// This determines the vertical position of the item in the dashboard.
  final int v;

  const ItemCoordinate(this.h, this.v);

  /// [Axis.horizontal]:
  ///   A B C
  ///   D E F
  /// [Axis.vertical]:
  ///  A D
  ///  B E
  ///  C F
  bool isBefore(ItemCoordinate other, DashboardAxis axis) {
    switch (axis) {
      case DashboardAxis.horizontal:
        if (v < other.v) {
          return true;
        } else if (v == other.v) {
          return h < other.h;
        } else {
          return false;
        }
      case DashboardAxis.vertical:
        if (h < other.h) {
          return true;
        } else if (h == other.h) {
          return v < other.v;
        } else {
          return false;
        }
    }
  }

  @override
  List<Object?> get props => [h, v];
}

class ItemRect extends Equatable {
  final ItemCoordinate origin;
  final ItemFlex flexes;

  const ItemRect(this.origin, this.flexes);

  int get left => origin.h;
  int get right => origin.h + flexes.horizontal;
  int get top => origin.v;
  int get bottom => origin.v + flexes.vertical;

  ItemCoordinate get bottomRight => ItemCoordinate(right, bottom);

  bool isOverlapped(ItemRect other) {
    return !(right <= other.left ||
        left >= other.right ||
        bottom <= other.top ||
        top >= other.bottom);
  }

  @override
  List<Object?> get props => [origin, flexes];
}
