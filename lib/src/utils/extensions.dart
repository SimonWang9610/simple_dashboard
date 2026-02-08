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
