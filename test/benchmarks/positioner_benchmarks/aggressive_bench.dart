import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

LayoutSize irregularSize(int index) {
  // Generate some irregular sizes for testing
  final width = (index % 3) + 1; // Width between 1 and 3
  final height = ((index + 1) % 4) + 1; // Height between 1 and 4
  return LayoutSize(width: width, height: height);
}

class AggressivePositionerBenchmark extends BenchmarkBase {
  AggressivePositionerBenchmark() : super('AggressivePositioner.addItem');

  @override
  void setup() {}

  @override
  void run() {
    List<LayoutItem> items = [];

    int maxCrossSlots = 0;

    // Stress test by adding 100 items with aggressive strategy
    for (int i = 0; i < 100; i++) {
      items =
          DashboardAggressivePositioner(
            items: items,
            axis: DashboardAxis.horizontal,
            mainAxisSlots: 10,
            maxCrossSlots: maxCrossSlots,
          ).position(
            "item_$i",
            irregularSize(i),
          );

      maxCrossSlots = items.fold(0, (int prev, item) {
        final bottom = item.rect.bottom;
        return bottom > prev ? bottom : prev;
      });
    }
  }

  static void main() {
    AggressivePositionerBenchmark().report();
  }
}

void main() {
  AggressivePositionerBenchmark.main();
}
