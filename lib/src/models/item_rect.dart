import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/models/enums.dart';
import 'package:simple_dashboard/src/models/item_flex.dart';

class ItemCoordinate extends Equatable {
  /// This determines the horizontal position of the item in the dashboard.
  /// typically, it should be X-axis
  final int h;

  /// This determines the vertical position of the item in the dashboard.
  /// typically, it should be Y-axis
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

  Offset operator *(double pixelsPerFlex) {
    return Offset(h * pixelsPerFlex, v * pixelsPerFlex);
  }

  @override
  List<Object?> get props => [h, v];
}

class ItemRect extends Equatable {
  /// The top-left coordinate of the item in the dashboard.
  final ItemCoordinate origin;

  /// The horizontal and vertical flexes of the item, which determine how much space the item will take up in the dashboard.
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

  /// Converts the coordinate to an [Offset] in pixels, given the number of pixels per flex,
  /// [hSpacing] is the total accumulated horizontal spacing before this coordinate,
  /// [vSpacing] is the total accumulated vertical spacing before this coordinate.
  Offset toOffset(
    double pixelsPerFlex, {
    double hSpacing = 0,
    double vSpacing = 0,
  }) {
    return origin * pixelsPerFlex + Offset(hSpacing, vSpacing);
  }

  Rect toRect(
    double pixelsPerFlex, {
    double hSpacing = 0,
    double vSpacing = 0,
  }) {
    final dx = left * (pixelsPerFlex + hSpacing);
    final dy = top * (pixelsPerFlex + vSpacing);
    final width =
        flexes.horizontal * pixelsPerFlex + (flexes.horizontal - 1) * hSpacing;
    final height =
        flexes.vertical * pixelsPerFlex + (flexes.vertical - 1) * vSpacing;

    return Rect.fromLTWH(dx, dy, width, height);
  }

  @override
  List<Object?> get props => [origin, flexes];

  @override
  String toString() {
    return 'ItemRect(left: $left, top: $top, right: $right, bottom: $bottom)';
  }
}
