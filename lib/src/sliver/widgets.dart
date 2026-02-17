import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/sliver/delegates.dart';
import 'package:simple_dashboard/src/sliver/render.dart';

class SliverDashboard extends SliverMultiBoxAdaptorWidget {
  final SliverDashboardDelegate layoutDelegate;
  const SliverDashboard({
    super.key,
    required super.delegate,
    required this.layoutDelegate,
  });

  @override
  RenderSliverDashboard createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element =
        context as SliverMultiBoxAdaptorElement;

    assert(() {
      final scrollable = context.findAncestorStateOfType<ScrollableState>();

      return switch (layoutDelegate.axis) {
        DashboardAxis.vertical => scrollable?.widget.axis == Axis.horizontal,
        DashboardAxis.horizontal => scrollable?.widget.axis == Axis.vertical,
      };
    }(), "SliverDashboard's storage axis must match the scrollable's axis.");

    return RenderSliverDashboard(
      childManager: element,
      layoutDelegate: layoutDelegate,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderSliverDashboard renderObject,
  ) {
    assert(() {
      final scrollable = context.findAncestorStateOfType<ScrollableState>();

      return switch (layoutDelegate.axis) {
        DashboardAxis.vertical => scrollable?.widget.axis == Axis.horizontal,
        DashboardAxis.horizontal => scrollable?.widget.axis == Axis.vertical,
      };
    }(), "SliverDashboard's storage axis must match the scrollable's axis.");

    renderObject.layoutDelegate = layoutDelegate;
  }
}

class DashboardView extends BoxScrollView {
  final SliverDashboardDelegate layoutDelegate;
  final DashboardItemBuilder itemBuilder;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;

  DashboardView.withDelegate({
    super.key,
    required this.layoutDelegate,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    required this.itemBuilder,
  }) : super(
         scrollDirection: layoutDelegate.axis == DashboardAxis.horizontal
             ? Axis.vertical
             : Axis.horizontal,
       );

  DashboardView.count({
    super.key,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    required DashboardAxis axis,
    required int mainAxisSlots,
    required List<LayoutItem> items,
    required this.itemBuilder,
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
         scrollDirection: axis == DashboardAxis.horizontal
             ? Axis.vertical
             : Axis.horizontal,
       );

  @override
  Widget buildChildLayout(BuildContext context) {
    return SliverDashboard(
      layoutDelegate: layoutDelegate,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final item = layoutDelegate.items[index];
          return itemBuilder(context, item);
        },
        childCount: layoutDelegate.items.length,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
      ),
    );
  }
}
