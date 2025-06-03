import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {

  MediaQueryData get media => MediaQuery.of(this);

  Size get screen => media.size;

  ThemeData get theme => Theme.of(this);

  double get maxMobileWidth => screen.shortestSide > 400 ? 400 : screen.width;

  bool get isTablet => screen.shortestSide >= 600;

  bool get isLandscapeTablet =>
      screen.shortestSide >= 600 && media.orientation == Orientation.landscape;
}