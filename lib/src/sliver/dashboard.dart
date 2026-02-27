import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

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
  });

  @override
  State<Dashboard> createState() => DashboardState();

  static DashboardState? of(BuildContext context) {
    return context.findAncestorStateOfType<DashboardState>();
  }

  static GlobalKey? getCacheKeyForItem(BuildContext context, Object itemId) {
    final state = of(context);
    if (state == null) return null;

    return state._itemCacheKeys.putIfAbsent(itemId, () => GlobalKey());
  }
}

class DashboardState extends State<Dashboard> with DashboardDragGestureHandler {
  final Map<Object, GlobalKey> _itemCacheKeys = {};

  ScrollController? _fallbackScrollController;

  ScrollController get _scrollController =>
      widget.scrollController ??
      (_fallbackScrollController ??= ScrollController());

  @override
  DashboardDragger get dragger => widget.controller;

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
              placeholderPainter: widget.controller.placeholderPainter,

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

mixin DashboardDragGestureHandler<T extends StatefulWidget> on State<T> {
  DashboardDragger get dragger;

  late final _dragGestureRecognizer = PanGestureRecognizer()
    ..onStart = _onDragStart
    ..onUpdate = _onDragUpdate
    ..onEnd = _onDragEnd
    ..onCancel = () => _endDrag(false);

  DragInfo? _dragInfo;
  OverlayEntry? _draggingOverlay;
  ValueNotifier<Offset>? _draggingGlobalOrigin;

  void absorbPointer(PointerDownEvent event, DragInfo dragInfo) {
    if (_dragInfo != null) return;

    _dragGestureRecognizer.addPointer(event);
    _dragInfo = dragInfo;
  }

  void _onDragStart(DragStartDetails details) {
    assert(_dragInfo != null);
    assert(_draggingOverlay == null);

    dragger.startDrag(_dragInfo!);

    _draggingGlobalOrigin?.dispose();
    _draggingGlobalOrigin = ValueNotifier(_dragInfo!.origin);

    final themeData = Theme.of(context);

    _draggingOverlay = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder(
          valueListenable: _draggingGlobalOrigin!,
          builder: (context, value, child) {
            return Positioned(
              left: value.dx,
              top: value.dy,
              child: child!,
            );
          },
          child: Theme(
            data: themeData,
            child: Material(
              child: SizedBox.fromSize(
                size: _dragInfo!.size,
                child: _dragInfo!.feedback,
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_draggingOverlay!);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_draggingGlobalOrigin != null) {
      _draggingGlobalOrigin!.value += details.delta;
    }
    dragger.updateDrag(details.delta);
  }

  void _onDragEnd(DragEndDetails details) {
    _endDrag(true);
  }

  void _endDrag(bool confirmed) {
    dragger.endDrag(confirmed);
    _dragInfo = null;
    _draggingOverlay?.remove();
    _draggingOverlay = null;
    _draggingGlobalOrigin?.dispose();
    _draggingGlobalOrigin = null;
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _endDrag(false);
  }

  @override
  void dispose() {
    _endDrag(false);
    _dragGestureRecognizer.dispose();
    super.dispose();
  }
}
