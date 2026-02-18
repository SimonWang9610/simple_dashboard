import 'dart:async';

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
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DashboardView.count(
                    axis: DashboardAxis.horizontal,
                    mainAxisSlots: 6,
                    physics: const ClampingScrollPhysics(),
                    items: initialItems,
                    addAutomaticKeepAlives: true,
                    itemBuilder: (context, item) {
                      return _ItemWidget(
                        item: item,
                      ); // Handle item removal if needed
                    },
                  ),
                ),
              ),
            ),

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
            //       return _ItemWidget(
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

class _ItemWidget extends StatefulWidget {
  final LayoutItem item;
  final VoidCallback? onRemove;
  final VoidCallback? onDoubleTap;
  const _ItemWidget({
    required this.item,
    this.onRemove,
    this.onDoubleTap,
  });

  @override
  State<_ItemWidget> createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<_ItemWidget>
    with AutomaticKeepAliveClientMixin {
  int count = 0;

  late final Timer timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('Creating item ${widget.item.id}');
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          count++;
        });
      },
    );
  }

  @override
  void didUpdateWidget(covariant _ItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      count = 0;
    }
  }

  @override
  void dispose() {
    print('Disposing item ${widget.item.id}');
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Item ${widget.item.id}'),
            content: Text(
              'Position: (${widget.item.rect.x}, ${widget.item.rect.y})\nSize: ${widget.item.rect.size.width} x ${widget.item.rect.size.height}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRemove?.call();
                },
                child: const Text('Remove'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      onDoubleTap: widget.onDoubleTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black),
          color: Colors
              .primaries[widget.item.id.hashCode % Colors.primaries.length]
              .withOpacity(0.5),
        ),
        child: Center(
          child: Text('[${widget.item.id}]: $count'),
        ),
      ),
    );
  }
}
