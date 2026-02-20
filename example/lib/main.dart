import 'package:example/item_widget.dart';
import 'package:example/sliver_example.dart';
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
      // home: _GridViewExample(),
      // home: const DashboardViewExample(),
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
    // initialItems: [
    //   LayoutItem(
    //     id: "initial-0",
    //     rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 5, height: 2)),
    //   ),

    //   LayoutItem(
    //     id: "initial-1",
    //     rect: LayoutRect(x: 5, y: 0, size: LayoutSize(width: 3, height: 1)),
    //   ),
    // ],
  );

  final placeholder = ValueNotifier<LayoutPlaceholder?>(null);

  final Map<Object, GlobalKey> itemKeys = {};

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
    placeholder.dispose();
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
              TextButton(
                onPressed: _togglePlaceholder,
                child: const Text('Toggle Placeholder'),
              ),
            ],
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: Dashboard(
                controller: controller,
                emptyBuilder: (context) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text('No items'),
                    ),
                  );
                },
                itemBuilder: (_, item) => ItemWidget(
                  key: itemKeys.putIfAbsent(item.id, () => GlobalKey()),
                  item: item,
                  onRemove: () {
                    controller.remove(item.id);
                  },
                ),
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
    print(
      "Adding item $id with size ${size.width} x ${size.height}, max slots: $slots",
    );

    controller.add(
      id,
      size,
      strategy: PositionStrategy.after,
      afterId: controller.items.firstOrNull?.id,
    );
  }

  void _togglePlaceholder() {}
}

class _GridViewExample extends StatefulWidget {
  const _GridViewExample({super.key});

  @override
  State<_GridViewExample> createState() => __GridViewExampleState();
}

class __GridViewExampleState extends State<_GridViewExample> {
  final items = List.generate(
    3,
    (index) => LayoutItem(
      id: "item $index",
      rect: LayoutRect(x: 0, y: 0, size: LayoutSize(width: 1, height: 1)),
    ),
  );

  final Map<Object, GlobalKey> itemKeys = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GridView Example")),
      body: Column(
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                items.insert(
                  1,
                  LayoutItem(
                    id: "item ${items.length}",
                    rect: LayoutRect(
                      x: 0,
                      y: 0,
                      size: LayoutSize(width: 1, height: 1),
                    ),
                  ),
                );
              });
            },
            child: const Text('Add Item'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ItemWidget(
                  key: itemKeys.putIfAbsent(
                    items[index].id,
                    () => GlobalKey(),
                  ),
                  item: items[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
