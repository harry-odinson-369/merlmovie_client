import 'package:merlmovie_client/src/models/wss.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HTTPClientBrowserModel {
  String id;
  WSSHttpDataModel info;
  WebViewController controller;

  HTTPClientBrowserModel({
    required this.id,
    required this.info,
    required this.controller,
  });
}
