import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

GlobalKey<NavigatorState> NavigatorKey = GlobalKey<NavigatorState>();

T use<T>() => Provider.of<T>(NavigatorKey.currentContext!, listen: false);
