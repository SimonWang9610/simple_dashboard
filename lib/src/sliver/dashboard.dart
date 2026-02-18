import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/defs.dart';
import 'package:simple_dashboard/src/sliver/controller.dart';

class Dashboard extends StatefulWidget {
  final DashboardController controller;
  final DashboardItemBuilder itemBuilder;
  final ScrollController? scrollController;

  const Dashboard({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.scrollController,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
