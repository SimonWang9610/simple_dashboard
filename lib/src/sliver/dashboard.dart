import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

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
}

class DashboardState extends State<Dashboard> {
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
              controller: widget.scrollController,
              cacheExtent: widget.cacheExtent,
              physics: widget.physics,
            );
          },
        ),
        Positioned.fill(child: loader),
      ],
    );
  }

  DashboardController get controller => widget.controller;

  List<LayoutItem>? _freezedItems;
  LayoutItem? _draggingItem;
  Offset _dragDelta = Offset.zero;

  double _dragSlotExtentX = 1.0;
  double _dragSlotExtentY = 1.0;

  void startDrag(LayoutItem item, Size widgetSize) {
    _freezedItems = List.unmodifiable(controller.items);
    _draggingItem = item;
    _dragDelta = Offset.zero;

    _dragSlotExtentX = widgetSize.width > 0
        ? widgetSize.width / item.rect.size.width
        : 1.0;
    _dragSlotExtentY = widgetSize.height > 0
        ? widgetSize.height / item.rect.size.height
        : 1.0;

    controller.items = _freezedItems!
        .map((i) => i.id == item.id ? i.placeholder : i)
        .toList();
  }

  void updateDrag(Offset delta) {
    _dragDelta += delta;

    final dx = (_dragDelta.dx / _dragSlotExtentX).round();
    final dy = (_dragDelta.dy / _dragSlotExtentY).round();

    final candidateRect = LayoutRect(
      x: _draggingItem!.rect.x + dx,
      y: _draggingItem!.rect.y + dy,
      size: _draggingItem!.rect.size,
    );

    if (!LayoutChecker.isValidRect(
      candidateRect,
      controller.axis,
      controller.mainAxisSlots,
    )) {
      return;
    }

    final result = LayoutChecker.checkCollisions(
      _freezedItems!.where(
        (i) => i.id != _draggingItem!.id && i is! LayoutPlaceholder,
      ),
      candidateRect,
    );

    if (!result.hasCollision) {
      final newPlaceholder = LayoutItem(
        id: _draggingItem!.id,
        rect: candidateRect,
      ).placeholder;

      controller.items = controller.items.map((i) {
        if (i.id == newPlaceholder.id) {
          return newPlaceholder;
        }
        return i;
      }).toList();
    }
  }

  void endDrag(bool confirmed) {
    if (confirmed) {
      controller.items = controller.items.map((i) {
        if (i is LayoutPlaceholder && i.item.id == _draggingItem!.id) {
          return i.item;
        }
        return i;
      }).toList();
    } else {
      controller.items = List.of(_freezedItems!);
    }

    _freezedItems = null;
    _draggingItem = null;
    _dragDelta = Offset.zero;
    _dragSlotExtentX = 1.0;
    _dragSlotExtentY = 1.0;
  }

  @override
  void dispose() {
    _currentDraggingOrigin?.dispose();
    _dragGestureRecognizer.dispose();
    super.dispose();
  }

  late final _dragGestureRecognizer = PanGestureRecognizer()
    ..onStart = _onDragStart
    ..onUpdate = _onDragUpdate
    ..onEnd = _onDragEnd;

  final autoScroll = AutoScrollController(edgeThreshold: 60, speed: 10);

  void routePointerEvent(PointerEvent event, DragInfo dragInfo) {
    if (_draggingItem != null) {
      return;
    }

    if (event is PointerDownEvent && dragInfo.item is! LayoutPlaceholder) {
      _dragGestureRecognizer.addPointer(event);
      _currentDragInfo = dragInfo;
    }
  }

  DragInfo? _currentDragInfo;

  ValueNotifier<Offset>? _currentDraggingOrigin;

  void _onDragStart(DragStartDetails details) {
    startDrag(_currentDragInfo!.item, _currentDragInfo!.size);

    _currentDraggingOrigin = ValueNotifier(_currentDragInfo!.origin);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder(
          key: _currentDragInfo!.itemKey,
          valueListenable: _currentDraggingOrigin!,
          builder: (context, value, child) {
            return Positioned(
              left: value.dx,
              top: value.dy,
              child: child!,
            );
          },
          child: widget.itemBuilder(context, _draggingItem!),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);

    autoScroll.start(context, details.localPosition);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    updateDrag(details.delta);

    if (_currentDraggingOrigin != null) {
      _currentDraggingOrigin!.value += details.delta;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    endDrag(true);
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentDraggingOrigin?.dispose();
    _currentDraggingOrigin = null;
    _currentDragInfo = null;

    autoScroll.stop();
  }

  OverlayEntry? _overlayEntry;
}

class DragInfo {
  final LayoutItem item;
  final GlobalKey itemKey;
  final Size size;
  final Offset origin;

  DragInfo({
    required this.item,
    required this.itemKey,
    required this.size,
    required this.origin,
  });
}
