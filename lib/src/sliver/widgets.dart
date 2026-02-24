import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

/// A mixin for widgets that represent a [LayoutItem] in the dashboard.
/// It enforces the widget to have an [item] property
/// that returns the corresponding [LayoutItem].
///
/// ```dart
/// class MyLayoutItemWidget extends StatelessWidget with LayoutItemWidget {
///   @override
///   final LayoutItem item;
///
///   const MyLayoutItemWidget({super.key, required this.item});
/// }
///
///
/// class MyDashboardItemWidget extends StatefulWidget with LayoutItemWidget {
///  @override
/// final LayoutItem item;
///
/// const MyDashboardItemWidget({super.key, required this.item});
///
/// @override
/// State<MyDashboardItemWidget> createState() => _MyDashboardItemWidgetState();
/// }
/// ```
mixin LayoutItemWidget on Widget {
  LayoutItem get item;
}

class SliverDashboard extends SliverMultiBoxAdaptorWidget {
  final SliverDashboardLayoutDelegate layoutDelegate;
  final DashboardPlaceholderPainter? placeholderPainter;

  const SliverDashboard({
    super.key,
    required SliverDashboardChildDelegate delegate,
    required this.layoutDelegate,
    this.placeholderPainter,
  }) : super(delegate: delegate);

  SliverDashboard.builder({
    super.key,
    required DashboardAxis axis,
    required int mainAxisSlots,
    required List<LayoutItem> items,
    required LayoutItemWidgetBuilder itemBuilder,
    this.placeholderPainter,
    double aspectRatio = 1.0,
    double mainAxisSpacing = 4,
    double crossAxisSpacing = 4,
  }) : layoutDelegate = SliverDashboardDelegateWithFixedSlotCount(
         mainAxisSlots: mainAxisSlots,
         items: items,
         axis: axis,
         aspectRatio: aspectRatio,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
       ),
       super(
         delegate: SliverDashboardBuilderDelegate.items(
           items: items,
           builder: itemBuilder,
         ),
       );

  SliverDashboard.list({
    super.key,
    required DashboardAxis axis,
    required int mainAxisSlots,
    required List<LayoutItemWidget> children,
    this.placeholderPainter,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double aspectRatio = 1.0,
    double mainAxisSpacing = 4,
    double crossAxisSpacing = 4,
  }) : layoutDelegate = SliverDashboardDelegateWithFixedSlotCount(
         mainAxisSlots: mainAxisSlots,
         items: children.map((child) => child.item).toList(),
         axis: axis,
         aspectRatio: aspectRatio,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
       ),
       super(
         delegate: SliverDashboardListDelegate(
           children: children,
           addAutomaticKeepAlives: addAutomaticKeepAlives,
           addRepaintBoundaries: addRepaintBoundaries,
           addSemanticIndexes: addSemanticIndexes,
         ),
       );

  @override
  RenderSliverDashboard createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element =
        context as SliverMultiBoxAdaptorElement;

    assert(
      () {
        final scrollable = context.findAncestorStateOfType<ScrollableState>();

        return switch (layoutDelegate.axis) {
          DashboardAxis.vertical => scrollable?.widget.axis == Axis.horizontal,
          DashboardAxis.horizontal => scrollable?.widget.axis == Axis.vertical,
        };
      }(),
      "SliverDashboard's axis does not match the scrollable's axis, given axis: ${layoutDelegate.axis}.",
    );

    return RenderSliverDashboard(
      childManager: element,
      layoutDelegate: layoutDelegate,
      placeholderPainter: placeholderPainter,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderSliverDashboard renderObject,
  ) {
    assert(
      () {
        final scrollable = context.findAncestorStateOfType<ScrollableState>();

        return switch (layoutDelegate.axis) {
          DashboardAxis.vertical => scrollable?.widget.axis == Axis.horizontal,
          DashboardAxis.horizontal => scrollable?.widget.axis == Axis.vertical,
        };
      }(),
      "SliverDashboard's axis does not match the scrollable's axis, given axis: ${layoutDelegate.axis}.",
    );

    renderObject
      ..layoutDelegate = layoutDelegate
      ..placeholderPainter = placeholderPainter;
  }
}

class DashboardView extends BoxScrollView {
  final SliverDashboardLayoutDelegate layoutDelegate;
  final SliverDashboardChildDelegate delegate;
  final DashboardPlaceholderPainter? placeholderPainter;

  DashboardView({
    super.key,
    required this.layoutDelegate,
    required this.delegate,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    this.placeholderPainter,
    super.hitTestBehavior,
  }) : super(
         scrollDirection: layoutDelegate.axis == DashboardAxis.horizontal
             ? Axis.vertical
             : Axis.horizontal,
       );

  DashboardView.builder({
    super.key,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    super.hitTestBehavior,
    this.placeholderPainter,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    required DashboardAxis axis,
    required int mainAxisSlots,
    required List<LayoutItem> items,
    required LayoutItemWidgetBuilder itemBuilder,
    double aspectRatio = 1.0,
    double mainAxisSpacing = 4,
    double crossAxisSpacing = 4,
  }) : layoutDelegate = SliverDashboardDelegateWithFixedSlotCount(
         mainAxisSlots: mainAxisSlots,
         items: items,
         axis: axis,
         aspectRatio: aspectRatio,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
       ),
       delegate = SliverDashboardBuilderDelegate.items(
         items: items,
         builder: itemBuilder,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
       ),
       super(
         scrollDirection: axis == DashboardAxis.horizontal
             ? Axis.vertical
             : Axis.horizontal,
       );

  DashboardView.list({
    super.key,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    super.hitTestBehavior,
    this.placeholderPainter,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    required DashboardAxis axis,
    required int mainAxisSlots,
    required List<LayoutItemWidget> children,
    double aspectRatio = 1.0,
    double mainAxisSpacing = 4,
    double crossAxisSpacing = 4,
  }) : layoutDelegate = SliverDashboardDelegateWithFixedSlotCount(
         mainAxisSlots: mainAxisSlots,
         items: children.map((child) => child.item).toList(),
         axis: axis,
         aspectRatio: aspectRatio,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
       ),
       delegate = SliverDashboardListDelegate(
         children: children,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
       ),
       super(
         scrollDirection: axis == DashboardAxis.horizontal
             ? Axis.vertical
             : Axis.horizontal,
       );

  @override
  Widget buildChildLayout(BuildContext context) {
    return SliverDashboard(
      layoutDelegate: layoutDelegate,
      delegate: delegate,
      placeholderPainter: placeholderPainter,
    );
  }
}
