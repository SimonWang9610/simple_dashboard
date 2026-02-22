import 'dart:async';

import 'package:example/item_widget.dart';
import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

class DashboardViewExample extends StatefulWidget {
  const DashboardViewExample({super.key});

  @override
  State<DashboardViewExample> createState() => _DashboardViewExampleState();
}

class _DashboardViewExampleState extends State<DashboardViewExample> {
  final initialItems = <LayoutItem>[
    LayoutItem(
      id: "initial-0",
      rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 3, height: 2)),
    ),
    LayoutItem(
      id: "initial-1",
      rect: LayoutRect(x: 3, y: 0, size: LayoutSize(width: 1, height: 4)),
    ),
    // LayoutItem(
    //   id: "initial-2",
    //   rect: LayoutRect(x: 0, y: 4, size: LayoutSize(width: 3, height: 3)),
    // ),

    // LayoutItem(
    //   id: "initial-3",
    //   rect: LayoutRect(x: 3, y: 4, size: LayoutSize(width: 2, height: 5)),
    // ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DashboardView Example")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text("DashboardView Example"),
              floating: true,
            ),
            SliverList.builder(
              itemCount: 3,
              itemBuilder: (context, index) => Text("Header $index"),
            ),

            // SliverDashboard.builder(
            //   axis: DashboardAxis.horizontal,
            //   mainAxisSlots: 5,
            //   items: initialItems,
            //   itemBuilder: (context, item) {
            //     return ItemWidget(item: item);
            //   },
            // ),
            SliverDashboard.list(
              axis: DashboardAxis.horizontal,
              mainAxisSlots: 5,
              children: initialItems
                  .map((item) => ItemWidget(item: item))
                  .toList(),
            ),

            SliverGrid.builder(
              itemCount: 3,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  color: Colors.blueGrey,
                  child: Center(child: Text("Grid Item $index")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
