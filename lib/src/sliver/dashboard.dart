import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/classes/drags.dart';
import 'package:simple_dashboard/src/controllers/mutator_state.dart';

class Dashboard extends StatefulWidget {
  final DashboardController controller;
  final DashboardItemBuilder itemBuilder;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;
  final double? cacheExtent;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double aspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? loadingBuilder;
  final ValueListenable<bool>? isLoading;
  final MoveDropStrategy moveDropStrategy;

  const Dashboard({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.scrollController,
    this.physics,
    this.cacheExtent,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.aspectRatio = 1.0,
    this.mainAxisSpacing = 4.0,
    this.crossAxisSpacing = 4.0,
    this.emptyBuilder,
    this.loadingBuilder,
    this.isLoading,
    this.moveDropStrategy = MoveDropStrategy.noCollision,
  });

  @override
  State<Dashboard> createState() => DashboardState();

  static DashboardState? of(BuildContext context) {
    return context.findAncestorStateOfType<DashboardState>();
  }

  static GlobalKey? getCacheKeyForItem(BuildContext context, Object itemId) {
    final state = of(context);
    if (state == null) return null;

    return state._itemCacheKeys.putIfAbsent(
      itemId,
      () => GlobalKey(debugLabel: "cacheKey-$itemId"),
    );
  }
}

class DashboardState extends State<Dashboard> with DashboardMutatingStateMixin {
  final Map<Object, GlobalKey> _itemCacheKeys = {};

  ScrollController? _fallbackScrollController;

  ScrollController get _scrollController =>
      widget.scrollController ??
      (_fallbackScrollController ??= ScrollController());

  @override
  DashboardItemMutator get mutator => widget.controller;

  @override
  DashboardMetricsManager get metrics => widget.controller;

  @override
  AutoScroll get autoScroll => _autoScroll;

  @override
  MoveDropStrategy get moveDropStrategy => widget.moveDropStrategy;

  late final AutoScroll _autoScroll = AutoScrollWithController(
    edgeThreshold: 50.0,
    speed: 10.0,
    direction: AxisDirection.down,
    controller: _scrollController,
  );

  @override
  void dispose() {
    _autoScroll.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emptyPlaceholder = ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final hasItems = widget.controller.items.isNotEmpty;

        return !hasItems && widget.emptyBuilder != null
            ? widget.emptyBuilder!(context)
            : const SizedBox.shrink();
      },
    );

    final loader = widget.isLoading != null
        ? ValueListenableBuilder(
            valueListenable: widget.isLoading!,
            builder: (context, isLoading, child) {
              return isLoading ? child! : emptyPlaceholder;
            },
            child:
                widget.loadingBuilder?.call(context) ??
                const Center(
                  child: CircularProgressIndicator(),
                ),
          )
        : emptyPlaceholder;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        ListenableBuilder(
          listenable: widget.controller,
          builder: (_, _) {
            return DashboardView.builder(
              /// DashboardView parameters
              items: widget.controller.sortedItems,
              axis: widget.controller.axis,
              mainAxisSlots: widget.controller.mainAxisSlots,
              itemBuilder: widget.itemBuilder,
              mainAxisSpacing: widget.mainAxisSpacing,
              crossAxisSpacing: widget.crossAxisSpacing,
              aspectRatio: widget.aspectRatio,
              addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
              addRepaintBoundaries: widget.addRepaintBoundaries,
              addSemanticIndexes: widget.addSemanticIndexes,

              /// scroll parameters
              controller: _scrollController,
              cacheExtent: widget.cacheExtent,
              physics: widget.physics,
            );
          },
        ),
        Positioned.fill(child: loader),
      ],
    );
  }
}
