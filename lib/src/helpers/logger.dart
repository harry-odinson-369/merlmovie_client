import 'dart:developer';

bool _isDebug = false;

class MerlMovieClientLogger {
  static void setDebug(bool isDebug) {
    _isDebug = isDebug;
  }

  static void logMsg(String msg) {
    if (_isDebug) log("[MerlMovie Client] $msg");
  }
}