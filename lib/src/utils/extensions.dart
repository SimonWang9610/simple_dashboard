import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/src/controllers/mutator_state.dart';

extension IntegerExtension on int {
  int clampInt(int lowerLimit, int upperLimit) {
    if (this < lowerLimit) {
      return lowerLimit;
    } else if (this > upperLimit) {
      return upperLimit;
    } else {
      return this;
    }
  }
}

extension DashboardMutatorFinderExt on BuildContext {
  DashboardMutatingStateMixin? ofDashboardMutator() {
    return findAncestorStateOfType<DashboardMutatingStateMixin>();
  }
}
