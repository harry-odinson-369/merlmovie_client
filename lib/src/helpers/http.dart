import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';
import 'package:merlmovie_client/src/global/global.vars.dart';
import 'package:merlmovie_client/src/helpers/generate.dart';
import 'package:merlmovie_client/src/helpers/map.dart';
import 'package:merlmovie_client/src/models/http_client_browser.dart';
import 'package:merlmovie_client/src/models/wss.dart';
import 'package:merlmovie_client/src/providers/browser.dart';
import 'package:merlmovie_client/src/widgets/browser.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HTTPRequest {
  // Uint8List? _getBody(WSSHttpDataModel info) {
  //   if (info.body == null) return null;
  //   if (info.body is String) {
  //     return utf8.encode(info.body!.toString());
  //   } else if (info.body is List) {
  //     return Uint8List.fromList(info.body! as List<int>);
  //   }
  //   return null;
  // }
  //
  // LoadRequestMethod _getMethod(WSSHttpDataModel info) {
  //   var method = LoadRequestMethod.values.firstWhereOrNull((e) {
  //     return e.name == info.method.toLowerCase();
  //   });
  //   return method ?? LoadRequestMethod.get;
  // }

  String get _channel => "HttpClientFlutter";
  String postMessage(String msg) => "$_channel.postMessage(`$msg`);";

  String _axiosCDN([String? cdn]) =>
      cdn ?? "https://cdn.jsdelivr.net/npm/axios@1.8.4/dist/axios.min.js";

  String _injectAxios({AxiosModel? axios}) {
    return """
       function injectAxios() {
          const script = document.createElement("script");
          script.src = "${_axiosCDN(axios?.cdn)}";
          script.onload = (ev) => {
             ${postMessage("injected")}
          };
          document.body.appendChild(script);
       }
       injectAxios();
    """;
  }

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
      }).then((resp) => {
        const data = Array.from(new Uint8Array(resp.data));
        ${postMessage("""
        \${JSON.stringify({
          status: resp.status,
          data: data,
          headers: resp.headers,
        })}
        """)};
      }).catch(err => {
        ${postMessage("""
        \${JSON.stringify({
          status: 500,
          data: Array.from(new TextEncoder().encode(err.message)),
          headers: {},
        })}
        """)}
      });"""}
    })(${json.encode(info.toMap())});
    """;
  }

  Future<Response> axios(WSSHttpDataModel info, {Duration? timeout}) async {
    var completer = Completer<Response>();
    Timer? timer;
    var controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          timer?.cancel();
          timer = null;
          timer = Timer(const Duration(seconds: 1), () {
            var script = _injectAxios(axios: info.axios);
            controller.runJavaScript(script);
          });
        },
      ),
    );
    controller.addJavaScriptChannel(
      _channel,
      onMessageReceived: (msg) async {
        if (msg.message == "injected") {
          Future.delayed(const Duration(milliseconds: 500), () {
            String script = _axiosRequest(info);
            controller.runJavaScript(script);
          });
        } else {
          var data = await compute(
            (message) => json.decode(message),
            msg.message,
          );
          var resp = Response.bytes(
            List<int>.from(data["data"]),
            data["status"],
            headers:
                MapUtilities.convert<String, String>(data["headers"]) ?? {},
          );
          completer.finish(resp);
        }
      },
    );
    controller.loadHtmlString(
      """
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>Document</title>
          </head>
          <body></body>
        </html>
      """,
      baseUrl: info.url,
    );
    var reqInfo = HTTPClientBrowserModel(
      id: GenerateHelper.random(1, 99).toString(),
      info: info,
      controller: controller,
    );
    NavigatorKey.currentContext?.read<BrowserProvider>().addRequest(reqInfo);
    var resp = await completer.future.timeout(
      timeout ?? const Duration(seconds: 16),
      onTimeout: () async => Response("Error Timeout!", 408),
    );
    timer?.cancel();
    timer = null;
    controller.setNavigationDelegate(NavigationDelegate());
    controller.loadRequest(Uri.parse("about:blank"));
    NavigatorKey.currentContext?.read<BrowserProvider>().removeRequest(reqInfo);
    return resp;
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
