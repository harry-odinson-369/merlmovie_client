import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/models/http_client_browser.dart';
import 'package:merlmovie_client/src/models/wss.dart';

class BrowserProvider extends ChangeNotifier {

  WSSBrowserWebDataModel? info;

  List<HTTPClientBrowserModel> httpRequests = [];

  void addRequest(HTTPClientBrowserModel requestInfo) {
    httpRequests = [requestInfo, ...httpRequests];
    notifyListeners();
  }

  void removeRequest(HTTPClientBrowserModel requestInfo) {
    httpRequests.removeWhere((e) => e.id == requestInfo.id);
    notifyListeners();
  }

  void clearHttpRequests() {
    httpRequests.clear();
    notifyListeners();
  }

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
