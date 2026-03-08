import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/controllers/mutator_state.dart';
import 'package:simple_dashboard/src/widgets/cache_key_store.dart';

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
  AutoScroll get autoScroll => (_autoScroll ??= AutoScrollWithController(
    speed: 10.0,
    direction: AxisDirection.down,
    controller: _scrollController,
  ));

  @override
  MoveDropStrategy get moveDropStrategy => widget.moveDropStrategy;

  AutoScroll? _autoScroll;

  @override
  void didUpdateWidget(covariant Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.scrollController != widget.scrollController) {
      _fallbackScrollController?.dispose();
      _fallbackScrollController = null;
      _autoScroll?.stop();
      _autoScroll = null;
    }
  }

  @override
  void dispose() {
    _fallbackScrollController?.dispose();
    _itemCacheKeys.clear();
    _autoScroll?.stop();
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

    return ItemCacheKeyStore(
      autoGenerateCacheKeys: true,
      cacheKeys: _itemCacheKeys,
      child: Stack(
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
      ),
    );
  }
}
