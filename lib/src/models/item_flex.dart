import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class ItemFlex extends Equatable {
  /// The horizontal flex of the item.
  /// This determines how much space the item will take up horizontally in relation to other items.
  final int horizontal;

  /// The vertical flex of the item.
  /// This determines how much space the item will take up vertically in relation to other items.
  final int vertical;

  const ItemFlex(this.horizontal, this.vertical)
    : assert(horizontal > 0 && vertical > 0);

  Size operator &(double pixelsPerFlex) {
    return Size(horizontal * pixelsPerFlex, vertical * pixelsPerFlex);
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

  ItemFlexRange.fixed(ItemFlex flex) : this(min: flex, max: flex);

  @override
  List<Object?> get props => [min, max];

  ItemFlex constrain(ItemFlex flex) {
    final constrainedHorizontal = flex.horizontal.clamp(
      min.horizontal,
      max.horizontal,
    );
    final constrainedVertical = flex.vertical.clamp(
      min.vertical,
      max.vertical,
    );

    return ItemFlex(constrainedHorizontal, constrainedVertical);
  }

  bool get isFixed => min == max;
}
