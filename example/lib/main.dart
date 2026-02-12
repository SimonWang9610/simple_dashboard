import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Simple Dashboard Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final controller = DashboardController(
    mainAxisSlots: 4,
    items: [
      LayoutItem(
        id: "initial-0",
        rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 5, height: 2)),
      ),

      LayoutItem(
        id: "initial-1",
        rect: LayoutRect(x: 5, y: 0, size: LayoutSize(width: 3, height: 1)),
      ),
    ],
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final screenSize = MediaQuery.sizeOf(context);

    final newMainAxSlots = switch (screenSize.width) {
      <= 400 => 4,
      <= 600 => 5,
      <= 800 => 6,
      _ => 9,
    };

    controller.mainAxisSlots = newMainAxSlots;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Column(
        spacing: 20,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(onPressed: _addItem, child: const Text('Add Item')),
              TextButton(
                onPressed: () {
                  setState(() {
                    controller.axis =
                        controller.axis == DashboardAxis.horizontal
                        ? DashboardAxis.vertical
                        : DashboardAxis.horizontal;
                  });
                },
                child: const Text('reverse axis'),
              ),
            ],
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border: Border.all(color: Colors.red),
              ),
              child: Dashboard(
                controller: controller,
                emptyBuilder: (context) => const Center(
                  child: Text('No items'),
                ),
                itemBuilder: (context, item) {
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
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  controller.removeItem(item.id);
                                });
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black),
                        color: Colors
                            .primaries[item.id.hashCode %
                                Colors.primaries.length]
                            .withOpacity(0.5),
                      ),
                      child: Center(
                        child: Text('[${item.id}]'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _count = 0;

  void _addItem() {
    if (controller.items.length > _count) {
      _count = controller.items.length;
    }

    final slots = controller.mainAxisSlots;

    final id = "Item${++_count}";

    final size = LayoutSize(
      width: faker.randomGenerator.integer(slots ~/ 2, min: 1),
      height: faker.randomGenerator.integer(slots ~/ 2, min: 1),
    );

    controller.addItem(
      id,
      size,
      strategy: PositionStrategy.head,
      afterId: controller.items.firstOrNull?.id,
    );
  }
}
