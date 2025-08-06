// ignore_for_file: deprecated_member_use

import 'dart:ui';

class ColorUtilities {
  static Color? fromHex(String? hexString) {
    if (hexString == null) return null;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String toHex(Color color, {bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${color.red.toRadixString(16).padLeft(2, '0')}'
      '${color.green.toRadixString(16).padLeft(2, '0')}'
      '${color.blue.toRadixString(16).padLeft(2, '0')}'
      '${color.alpha.toRadixString(16).padLeft(2, '0')}';

  static String resolveHex(String hex) {
    if (hex.length == 9 && hex.endsWith("ff")) {
      return hex.substring(0, hex.length - 2);
    } else if (hex.length == 8 && hex.endsWith("ff")) {
      return hex.substring(0, hex.length - 2);
    } else {
      return hex;
    }
  }
}
