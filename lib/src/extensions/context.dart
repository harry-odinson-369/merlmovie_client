import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {

  MediaQueryData get media => MediaQuery.of(this);

  Size get screen => media.size;

  ThemeData get theme => Theme.of(this);
}