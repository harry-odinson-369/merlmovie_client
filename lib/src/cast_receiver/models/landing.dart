import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/helpers/color.dart';

class LandingModel {
  String appName = "Media Receiver";
  String appLogo = "";

  Color appNameColor = Colors.red;
  Color backgroundColor = Colors.black;

  LandingModel({
    this.appName = "Media Receiver",
    this.appLogo = "",
    this.appNameColor = Colors.white,
    this.backgroundColor = Colors.black,
  });

  factory LandingModel.fromMap(Map<String, dynamic> map) => LandingModel(
    appName: map["app_name"] ?? "Media Receiver",
    appLogo: map["app_logo"] ?? "",
    appNameColor: ColorUtilities.fromHex(map["app_name_color"]) ?? Colors.white,
    backgroundColor: ColorUtilities.fromHex(map["background_color"]) ?? Colors.white,
  );

  Map<String, dynamic> toMap() => {
    "app_name": appName,
    "app_logo": appLogo,
    "app_name_color": ColorUtilities.resolveHex(ColorUtilities.toHex(appNameColor)),
    "background_color": ColorUtilities.resolveHex(ColorUtilities.toHex(backgroundColor)),
  };

}
