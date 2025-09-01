import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';
import 'package:merlmovie_client/src/helpers/map.dart';
import 'package:merlmovie_client/src/models/wss.dart';
import 'package:merlmovie_client/src/widgets/browser.dart';

class HTTPRequest {
  String get _channel => "axios_flutter";
  String _callHandler(String args) =>
      "window.flutter_inappwebview.callHandler(`$_channel`, $args);";

  String _axiosCDN([String? cdn]) =>
      cdn ?? "https://cdn.jsdelivr.net/npm/axios@1.8.4/dist/axios.min.js";

  String _axiosRequest(WSSHttpDataModel info) {
    return """
    (function(args) {
      ${info.axios.script ?? """axios.request({
        url: args.url,
        method: args.method,
        headers: args.headers,
        data: args.body,
        responseType: "arraybuffer",
        validateStatus: () => true,
        withCredentials: args.with_credentials === true,
      }).then((resp) => {
        const data = Array.from(new Uint8Array(resp.data));
        ${_callHandler("...[data, resp.status, resp.headers]")}
      }).catch(err => {
        const data = Array.from(new TextEncoder().encode(err.message));
        ${_callHandler("...[data, 500, {}]")}
      });"""}
    })(${json.encode(info.toMap())});
    """;
  }

  String get _htmlPlaceholder {
    return """
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>Document</title>
          </head>
          <body></body>
        </html>
        """;
  }

  void _onLoadStop(
    InAppWebViewController controller,
    Completer<Response> completer,
    WSSHttpDataModel info,
  ) {
    controller.addJavaScriptHandler(
      handlerName: _channel,
      callback: (arguments) {
        completer.finish(
          Response.bytes(
            List<int>.from(arguments[0]),
            arguments[1],
            headers: MapUtilities.convert<String, String>(arguments[2]) ?? {},
          ),
        );
      },
    );
    controller.injectJavascriptFileFromUrl(
      urlFile: WebUri(_axiosCDN(info.axios.cdn)),
      scriptHtmlTagAttributes: ScriptHtmlTagAttributes(
        onLoad: () {
          controller.callAsyncJavaScript(functionBody: _axiosRequest(info));
        },
        onError: () {
          completer.finish(Response("Error cannot use axios!", 500));
        },
        id: "axios",
      ),
    );
  }

  Future<Response> axios(WSSHttpDataModel info, {Duration? timeout}) async {
    var completer = Completer<Response>();
    Timer? timer;
    var cookie = (info.headers?["cookie"] ?? info.headers?["Cookie"]);
    var userAgent = info.headers?["User-Agent"] ?? info.headers?["user-agent"];
    if (cookie != null) await BrowserWidget.setCookie(info.url, cookie);
    var headless = HeadlessInAppWebView(
      initialUrlRequest:
          info.initial_origin != null
              ? URLRequest(
                url: WebUri(info.initial_origin!),
                cachePolicy: URLRequestCachePolicy.RETURN_CACHE_DATA_ELSE_LOAD,
              )
              : null,
      initialData:
          info.initial_origin == null
              ? InAppWebViewInitialData(
                data: _htmlPlaceholder,
                baseUrl: WebUri(info.url),
              )
              : null,
      initialSettings: InAppWebViewSettings(userAgent: userAgent),
      onLoadStop: (controller, url) {
        if (info.initial_origin != null) {
          timer?.cancel();
          timer = null;
          timer = Timer(const Duration(seconds: 1), () {
            _onLoadStop(controller, completer, info);
          });
        } else {
          _onLoadStop(controller, completer, info);
        }
      },
    )..run().catchError((err) {});
    MerlMovieClientLogger.logMsg(
      "Created a new headless webview and making axios client request.",
    );
    var response = await completer.future.timeout(
      timeout ?? Duration(seconds: 16),
      onTimeout: () => Future.value(Response("Error connection timeout.", 408)),
    );
    timer?.cancel();
    timer = null;
    await headless.dispose().catchError((err) {});
    MerlMovieClientLogger.logMsg(
      "Closed a headless webview with status code: ${response.statusCode}.",
    );
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
