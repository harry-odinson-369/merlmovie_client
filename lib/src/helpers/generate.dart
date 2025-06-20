import 'dart:math';

class GenerateHelper {
  static int random(int min, int max) {
    if ((max - min) < 0 || max == 0) {
      return min;
    } else {
      return min + Random().nextInt(max - min);
    }
  }
}
