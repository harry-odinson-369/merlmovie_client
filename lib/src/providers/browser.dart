import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/models/wss.dart';

class BrowserProvider extends ChangeNotifier {

  WSSBrowserWebDataModel? info;

  void spawn(WSSBrowserWebDataModel data) {
    info = data;
    notifyListeners();
  }

  void visible(BrowserWebVisible vi) {
    info?.visible = vi;
    notifyListeners();
  }

  void close() {
    info = null;
    notifyListeners();
  }
}
