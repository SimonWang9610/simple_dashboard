import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

class DashboardAddItemsBenchmark extends BenchmarkBase {
  DashboardAddItemsBenchmark() : super('DashboardController.add');

  @override
  void setup() {}

  @override
  void run() {
    final controller = DashboardController(mainAxisSlots: 10);

    LayoutSize irregularSize(int index) {
      // Generate some irregular sizes for testing
      final width = (index % 3) + 1; // Width between 1 and 3
      final height = ((index + 1) % 4) + 1; // Height between 1 and 4
      return LayoutSize(width: width, height: height);
    }

    // Stress test by adding 50 items with aggressive strategy
    for (int i = 0; i < 100; i++) {
      controller.add(
        'item_$i',
        irregularSize(i),
        strategy: PositionStrategy.aggressive,
      );
    }
  }

  static void main() {
    DashboardAddItemsBenchmark().report();
  }
}

void main() {
  DashboardAddItemsBenchmark.main();
}
