import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/widgets/animated_dashboard_layout.dart';

typedef DashboardItemBuilder =
    Widget Function(BuildContext context, LayoutItem);

class Dashboard extends StatefulWidget {
  final DashboardController controller;
  final DashboardItemBuilder itemBuilder;
  final WidgetBuilder? emptyBuilder;
  final double aspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const Dashboard({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.aspectRatio = 1.0,
    this.mainAxisSpacing = 4,
    this.crossAxisSpacing = 4,
    this.emptyBuilder,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (_, child) {
        final items = widget.controller.items;

        if (items.isEmpty) {
          return child ?? const SizedBox.shrink();
        }

        return SingleChildScrollView(
          scrollDirection: widget.controller.axis == DashboardAxis.horizontal
              ? Axis.vertical
              : Axis.horizontal,
          child: RawDashboard(
            axis: widget.controller.axis,
            mainAxisSlots: widget.controller.mainAxisSlots,
            layoutDelegate: DashboardAspectRatioDelegate(
              aspectRatio: widget.aspectRatio,
              mainAxisSpacing: widget.mainAxisSpacing,
              crossAxisSpacing: widget.crossAxisSpacing,
            ),
            children: [
              for (int i = 0; i < items.length; i++)
                AnimatedDashboardLayout(
                  key: ValueKey(items[i].id),
                  rect: items[i].rect,
                  curve: Curves.linear,
                  duration: const Duration(milliseconds: 160),
                  child: widget.itemBuilder(context, items[i]),
                ),
            ],
          ),
        );
      },
      child: widget.emptyBuilder?.call(context),
    );
  }
}
