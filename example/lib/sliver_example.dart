import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

class DashboardViewExample extends StatefulWidget {
  const DashboardViewExample({super.key});

  @override
  State<DashboardViewExample> createState() => _DashboardViewExampleState();
}

class _DashboardViewExampleState extends State<DashboardViewExample> {
  final initialItems = [
    LayoutItem(
      id: "initial-0",
      rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 5, height: 2)),
    ),

    LayoutItem(
      id: "initial-2",
      rect: LayoutRect(x: 0, y: 3, size: LayoutSize(width: 3, height: 3)),
    ),
    LayoutItem(
      id: "initial-1",
      rect: LayoutRect(x: 5, y: 0, size: LayoutSize(width: 1, height: 3)),
    ),
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
                child: DashboardView.count(
                  axis: DashboardAxis.horizontal,
                  mainAxisSlots: 6,
                  items: initialItems,
                  itemBuilder: (context, item) {
                    return _ItemWidget(
                      item: item,
                    ); // Handle item removal if needed
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemWidget extends StatelessWidget {
  final LayoutItem item;
  final VoidCallback? onRemove;
  final VoidCallback? onDoubleTap;
  const _ItemWidget({
    required this.item,
    this.onRemove,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Item ${item.id}'),
            content: Text(
              'Position: (${item.rect.x}, ${item.rect.y})\nSize: ${item.rect.size.width} x ${item.rect.size.height}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRemove?.call();
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
      onDoubleTap: onDoubleTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black),
          color: Colors.primaries[item.id.hashCode % Colors.primaries.length]
              .withOpacity(0.5),
        ),
        child: Center(
          child: Text('[${item.id}]'),
        ),
      ),
    );
  }
}
