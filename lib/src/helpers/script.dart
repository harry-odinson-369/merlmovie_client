import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScriptHelper {

  static Future<String?> getScriptFromUrl(String url) async {
    var pref = await SharedPreferences.getInstance();
    String key = urlToPrefsKey(url);
    String? script = pref.getString(key);
    if (script != null) {
      debugPrint("[MerlMovieClient] Got the script from cache.");
      return script;
    }
    var resp = await get(Uri.parse(url));
    if (resp.statusCode != 200) return null;
    await pref.setString(key, resp.body).catchError((er) { return false; });
    debugPrint("[MerlMovieClient] Got the script from network.");
    return resp.body;
  }

  static Future remove(String url) async {
    var pref = await SharedPreferences.getInstance();
    String key = urlToPrefsKey(url);
    bool done = await pref.remove(key);
    if (done) debugPrint("[MerlMovieClient] Script removed.");
  }

  static String urlToPrefsKey(String url) {
    final bytes = utf8.encode(url.trim().toLowerCase());
    return 'url_${sha1.convert(bytes)}';
  }
}
