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
  DashboardController controller = DashboardController(
    mainAxisFlexCount: 9,
    // mainAxisSpacing: 6,
    // crossAxisSpacing: 6,
  );

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
                onPressed: _reorderItem,
                child: const Text('Reorder Item'),
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
    final mainAxisFlex = controller.mainAxisFlexCount;

    final mainFlex = faker.randomGenerator.integer(mainAxisFlex ~/ 2, min: 1);
    final crossFlex = faker.randomGenerator.integer(mainAxisFlex ~/ 2, min: 1);

    final itemFlex = ItemFlex(mainFlex, crossFlex);

    controller.addItem(
      DateTime.now().toString(),
      itemFlex,
      ItemFlexRange.fixed(itemFlex),
    );
  }

  void _reorderItem() {
    if (controller.items.length < 2) return;

    controller.reorderItem(0, 1);
  }
}
