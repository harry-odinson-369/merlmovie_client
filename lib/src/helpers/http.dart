import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';
import 'package:merlmovie_client/src/helpers/logger.dart';
import 'package:merlmovie_client/src/helpers/map.dart';
import 'package:merlmovie_client/src/models/wss.dart';
import 'package:merlmovie_client/src/widgets/browser.dart';

class HTTPRequest {
  Future<Response> axios(WSSHttpDataModel info, {Duration? timeout}) async {
    Completer<Response> completer = Completer<Response>();
    String? cookie = (info.headers?["cookie"] ?? info.headers?["Cookie"]);
    if (cookie != null) {
      await BrowserWidget.setCookie(info.url, cookie);
    }
    final hl = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(info.url),
        method: info.method.toUpperCase(),
        headers: info.headers,
      ),
      initialSettings: InAppWebViewSettings(
        userAgent: info.headers?["User-Agent"] ?? info.headers?["user-agent"],
      ),
      onLoadStop: (controller, url) {
        controller.addJavaScriptHandler(
          handlerName: "axios_result",
          callback: (arguments) {
            completer.finish(
              Response.bytes(
                List<int>.from(arguments[2]),
                arguments[0],
                headers:
                    MapUtilities.convert<String, String>(arguments[1]) ?? {},
              ),
            );
          },
        );
        controller.injectJavascriptFileFromUrl(
          urlFile: WebUri(
            info.axios.cdn ??
                "https://cdn.jsdelivr.net/npm/axios@1.8.4/dist/axios.min.js",
          ),
          scriptHtmlTagAttributes: ScriptHtmlTagAttributes(
            onLoad: () {
              controller.callAsyncJavaScript(
                functionBody:
                    info.axios.script ??
                    """
                  axios
                    .request({
                      url: __axios_url,
                      method: __axios_method,
                      headers: __axios_headers,
                      data: __axios_data,
                      responseType: "arraybuffer",
                      validateStatus: () => true,
                    })
                    .then((resp) => {
                      const data = Array.from(new Uint8Array(resp.data));
                      const args = [resp.status, resp.headers, data];
                      window.flutter_inappwebview.callHandler("axios_result", ...args);
                    });
                """,
                arguments: {
                  "__axios_url": info.url,
                  "__axios_method": info.method.toUpperCase(),
                  "__axios_data": info.body,
                  "__axios_headers": info.headers,
                  "__axios_response_type": "bytes",
                },
              );
            },
            onError: () {
              completer.finish(Response("Error cannot use axios!", 500));
            },
            id: "axios",
          ),
        );
      },
    )..run();
    MerlMovieClientLogger.logMsg(
      "[Axios Request] Spawn a headless browser and making http request.",
    );
    if (timeout != null) {
      Future.delayed(timeout, () {
        completer.finish(Response("Error connection timeout.", 408));
      });
    }
    final response = await completer.future;
    await hl.dispose();
    MerlMovieClientLogger.logMsg("[Axios Request] Closed headless browser.");
    return response;
  }

  String resolveCookie(String cookie) {
    final cookiePairs = [];
    for (final co in cookie.split(",")) {
      final parts = co.split(";");
      final kv = parts[0].split("=").map((e) => e.trim()).toList();
      if (kv.length >= 2) {
        cookiePairs.add("${kv[0]}=${kv[1]}");
      }
    }
    return cookiePairs.reversed.toList().join("; ");
  }

  Future<Response> request(WSSHttpDataModel info) async {
    var client = Client();
    try {
      var request = Request(info.method.toUpperCase(), Uri.parse(info.url));
      if (info.headers != null) {
        request.headers.addAll(info.headers ?? <String, String>{});
      }
      bool isBodyString = info.body is String;
      if (info.body != null && isBodyString) {
        request.body = info.body.toString();
      }
      if (info.body != null && !isBodyString && info.body is List) {
        request.bodyBytes = Uint8List.fromList(info.body as List<int>);
      }
      var stream = await client.send(request);
      var resp = await Response.fromStream(stream);
      if (resp.headers["set-cookie"] != null) {
        await BrowserWidget.setCookie(
          info.url,
          resolveCookie(resp.headers["set-cookie"].toString()),
        );
      }
      return resp;
    } finally {
      client.close();
    }
  }
}
