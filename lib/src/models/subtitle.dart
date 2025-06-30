// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubtitleTheme {
  Color textColor;
  Color backgroundColor;
  double backgroundOpacity;
  double bottomPad;
  FontWeight fontWeight;
  FontStyle fontStyle;
  double fontSize;

  SubtitleTheme({
    required this.textColor,
    required this.backgroundColor,
    required this.backgroundOpacity,
    required this.bottomPad,
    required this.fontWeight,
    required this.fontStyle,
    required this.fontSize,
  });

  static const String _key = "_subtitle_theme";

  static Future<SubtitleTheme> getTheme() async {
    var data = (await SharedPreferences.getInstance()).getString(_key);
    return SubtitleTheme.fromMap(data != null ? json.decode(data) : {});
  }

  static Future setTheme(SubtitleTheme theme) async {
    return (await SharedPreferences.getInstance()).setString(
      _key,
      json.encode(theme.toMap()),
    );
  }

  SubtitleTheme copyWith({
    Color? textColor,
    Color? backgroundColor,
    double? backgroundOpacity,
    double? bottomPad,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? fontSize,
}) => SubtitleTheme(
    textColor: textColor ?? this.textColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    bottomPad: bottomPad ?? this.bottomPad,
    fontWeight: fontWeight ?? this.fontWeight,
    fontStyle: fontStyle ?? this.fontStyle,
    fontSize: fontSize ?? this.fontSize,
  );

  factory SubtitleTheme.fromMap(Map<String, dynamic> map) => SubtitleTheme(
    textColor: Color(map["textColor"] ?? Colors.white.value),
    backgroundColor: Color(map["backgroundColor"] ?? Colors.black.value),
    backgroundOpacity: map["backgroundOpacity"] ?? .8,
    bottomPad: map["bottomPad"] ?? 24,
    fontWeight: FontWeight.values.firstWhere(
      (e) => e.value == (map["fontWeight"] ?? FontWeight.w500.value),
    ),
    fontStyle: FontStyle.values.firstWhere(
      (e) => e.name == (map["fontStyle"] ?? FontStyle.normal.name),
    ),
    fontSize: map["fontSize"] ?? 18,
  );

  Map<String, dynamic> toMap() => {
    "textColor": textColor.value,
    "backgroundColor": backgroundColor.value,
    "backgroundOpacity": backgroundOpacity,
    "bottomPad": bottomPad,
    "fontWeight": fontWeight.value,
    "fontStyle": fontStyle.name,
    "fontSize": fontSize,
  };
}
