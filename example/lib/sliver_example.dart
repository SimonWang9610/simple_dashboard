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
    // LayoutItem(
    //   id: "initial-0",
    //   rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 5, height: 2)),
    // ),
    LayoutItem(
      id: "initial-1",
      rect: LayoutRect(x: 5, y: 0, size: LayoutSize(width: 1, height: 4)),
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
        child: Column(
          children: [
            // Expanded(
            //   child: DecoratedBox(
            //     decoration: BoxDecoration(
            //       border: Border.all(color: Colors.blueAccent, width: 2),
            //     ),
            //     child: Padding(
            //       padding: const EdgeInsets.all(8.0),
            //       child: DashboardView.count(
            //         axis: DashboardAxis.horizontal,
            //         mainAxisSlots: 6,
            //         physics: const ClampingScrollPhysics(),
            //         items: initialItems,
            //         addAutomaticKeepAlives: true,
            //         itemBuilder: (context, item) {
            //           return ItemWidget(
            //             item: item,
            //           ); // Handle item removal if needed
            //         },
            //       ),
            //     ),
            //   ),
            // ),
            // DecoratedBox(
            //   decoration: BoxDecoration(
            //     border: Border.all(color: Colors.blueAccent, width: 2),
            //   ),
            //   child: DashboardView.count(
            //     axis: DashboardAxis.horizontal,
            //     mainAxisSlots: 6,
            //     shrinkWrap: true,
            //     // physics: const ClampingScrollPhysics(),
            //     // items: DashboardHelper.sort(
            //     //   initialItems,
            //     //   DashboardAxis.horizontal,
            //     // ),
            //     items: initialItems,
            //     addAutomaticKeepAlives: true,
            //     itemBuilder: (context, item) {
            //       return ItemWidget(
            //         item: item,
            //       ); // Handle item removal if needed
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
