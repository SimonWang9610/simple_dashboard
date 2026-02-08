import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/utils/extensions.dart';

class ItemFlex extends Equatable {
  /// The horizontal flex of the item.
  /// This determines how much space the item will take up horizontally in relation to other items.
  final int horizontal;

  /// The vertical flex of the item.
  /// This determines how much space the item will take up vertically in relation to other items.
  final int vertical;

  const ItemFlex(this.horizontal, this.vertical)
    : assert(horizontal >= 0 && vertical >= 0);

  BoxConstraints toConstraints(double horizontalUnit, double verticalUnit) {
    return BoxConstraints.tight(
      Size(horizontal * horizontalUnit, vertical * verticalUnit),
    );
  }

  @override
  List<Object?> get props => [horizontal, vertical];
}

/// A class that represents the minimum and maximum flexes of an item.
class ItemFlexRange extends Equatable {
  final ItemFlex min;
  final ItemFlex max;

  ItemFlexRange({
    required this.min,
    required this.max,
  }) : assert(
         min.horizontal <= max.horizontal &&
             min.vertical <= max.vertical &&
             min.horizontal >= 0 &&
             min.vertical >= 0,
       );

  @override
  List<Object?> get props => [min, max];

  ItemFlex resize(
    ItemFlex flex, {
    int? hStep,
    int? vStep,
  }) {
    if (hStep == null && vStep == null) {
      return flex;
    }

    final h = flex.horizontal + (hStep ?? 0);
    final v = flex.vertical + (vStep ?? 0);

    return ItemFlex(
      h.clampInt(min.horizontal, max.horizontal),
      v.clampInt(min.vertical, max.vertical),
    );
  }
}
