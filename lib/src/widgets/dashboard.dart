import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

typedef DashboardItemBuilder =
    Widget Function(BuildContext context, DashboardItem);

class Dashboard extends StatefulWidget {
  final DashboardController controller;
  final DashboardItemBuilder itemBuilder;
  final WidgetBuilder? emptyBuilder;

  const Dashboard({
    super.key,
    required this.controller,
    required this.itemBuilder,
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
            layoutNotifier: widget.controller,
            children: [
              for (int i = 0; i < items.length; i++)
                DashboardItemDataWidget(
                  key: ValueKey(items[i].id),
                  rect: items[i].rect,
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
