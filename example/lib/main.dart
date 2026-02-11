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
  final controller = DashboardController(mainAxisSlots: 6);

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
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black),
                      color: Colors
                          .primaries[item.id.hashCode % Colors.primaries.length]
                          .withOpacity(0.5),
                    ),
                    child: Center(
                      child: Text('[${item.id}]'),
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

  void _addItem() {
    final slots = controller.mainAxisSlots;

    final id = "Item:${controller.items.length + 1}";

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
