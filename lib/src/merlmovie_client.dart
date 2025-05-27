import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:merlmovie_client/src/controllers/socket_controller.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/global/global.vars.dart';
import 'package:merlmovie_client/src/helpers/http.dart';
import 'package:merlmovie_client/src/helpers/information.dart';
import 'package:merlmovie_client/src/helpers/logger.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:merlmovie_client/src/models/wss.dart';
import 'package:merlmovie_client/src/providers/browser.dart';
import 'package:merlmovie_client/src/widgets/browser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

SocketController? _controller;

class MerlMovieClient {
  static SocketController? get socket => _controller;

  static Future<DirectLink?> request(
    EmbedModel embed, {
    void Function(int status, String message)? onError,
    void Function(double progress)? onProgress,
  }) async {
    DirectLink? directLink;
    try {
      directLink = await _request(embed, onProgress: onProgress);
    } catch(_) {}
    directLink ??= await _request(embed, onProgress: onProgress, onError: onError);
    return directLink;
  }

  static Future<DirectLink?> _request(
    EmbedModel embed, {
    void Function(int status, String message)? onError,
    void Function(double progress)? onProgress,
  }) async {
    Response response;

    LoggerHelper.logMsg("Requesting to target ${embed.requestUrl}...");

    String requestUrl = await InformationHelper.requestUrlWithXCI(
      embed.requestUrl,
    );

    if (embed.isWSS) {
      _controller = SocketController(requestUrl);
      response = await _requestWSS(_controller, embed, onProgress: onProgress);
      await _controller?.close();
      _controller = null;
    } else {
      try {
        response = await get(
          Uri.parse(requestUrl),
          headers: embed.plugin.headers,
        );
      } catch (err) {
        LoggerHelper.logMsg("Error! ${err.toString()}");
        response = _errorResponse(500, "Unexpected error occurred!");
      }
    }

    if (response.statusCode == HttpStatus.ok) {
      final data = await _computeData(response.body);
      if (data != null) {
        final directLink = DirectLink.fromMap(data);
        if (directLink.qualities.isAllMatched((e) => e.link.isNotEmpty)) {
          return directLink;
        }
      }
    } else {
      try {
        final res = json.decode(response.body);
        if (res["msg"] != null || res["message"] != null) {
          String msg =
              res["msg"] ??
              res["message"] ??
              "Unexpected error! Please try again.";
          onError?.call(response.statusCode, msg);
          LoggerHelper.logMsg(msg);
        }
      } catch (err) {
        LoggerHelper.logMsg("Error! cannot get direct link at the moment.");
        onError?.call(500, "Cannot get direct link! unexpected error.");
      }
    }

    return null;
  }

  static Future<Response> _requestWSS(
    SocketController? socket,
    EmbedModel embed, {
    void Function(double percent)? onProgress,
  }) async {
    Completer<Response> completer = Completer<Response>();
    try {
      bool? isReady = await socket?.ready;
      if (isReady == false) {
        return _errorResponse(
          408,
          "Error connection timeout! Please check your internet connection and try again.",
        );
      }

      LoggerHelper.logMsg("Request using websocket. ready to communicate.");

      void handler(dynamic event) async {
        final decoded = json.decode(event.toString());
        final wss = WSSDataModel.fromMap(decoded);

        if (wss.action == WSSAction.fetch && wss.httpInfo.url.isNotEmpty) {
          if (wss.httpInfo.url.startsWith("http")) {
            await _wssHttpRequest(_controller, wss);
          } else if (wss.httpInfo.url.startsWith("db")) {
            await _wssDbRequest(_controller, wss, embed);
          }
        } else if (wss.action == WSSAction.progress) {
          onProgress?.call(double.parse("${wss.data["progress"] ?? 0}"));
        } else if (wss.action == WSSAction.result) {
          navigatorKey.currentContext?.read<BrowserProvider>().close();
          completer.finish(Response(json.encode(wss.data), 200));
        } else if (wss.action == WSSAction.failed) {
          completer.finish(Response(json.encode(wss.data), wss.data["status"]));
        } else if (wss.action == WSSAction.browser) {
          navigatorKey.currentContext?.read<BrowserProvider>().spawn(
            wss.browserInfo,
          );
        } else if (wss.action == WSSAction.browser_close) {
          navigatorKey.currentContext?.read<BrowserProvider>().close();
        } else if (wss.action == WSSAction.browser_cookie) {
          final cookie = await BrowserWidget.getCookie(wss.data["url"]);
          final data = WSSDataModel(
            action: WSSAction.browser_cookie_result,
            id: wss.id,
            data: {"cookie": cookie},
          );
          socket?.sendMessage(json.encode(data.toMap()));
        } else if (wss.action == WSSAction.browser_set_cookie) {
          await BrowserWidget.setCookie(wss.data["url"], wss.data["cookie"]);
        } else if (wss.action == WSSAction.browser_visible) {
          navigatorKey.currentContext?.read<BrowserProvider>().visible(
            wss.visible,
          );
        }
      }

      socket?.message?.listen(handler);

      final mediaInfo = {
        "media_type": embed.type,
        "media_id": embed.plugin.useIMDb ? embed.imdbId : embed.tmdbId,
        "season_id": embed.season,
        "episode_id": embed.episode,
        "data": embed.detail,
      };
      final streamData = WSSDataModel(
        action: WSSAction.stream,
        data: mediaInfo,
      );
      socket?.sendMessage(json.encode(streamData.toMap()));
    } catch (err) {
      LoggerHelper.logMsg("Error! ${err.toString()}");
      completer.finish(_errorResponse(500, "Unexpected error occurred!"));
    }

    return completer.future;
  }

  static Future<Map<String, dynamic>?> _computeData(String data) async {
    var content = await compute<String, dynamic>((content) async {
      try {
        var jsonData = json.decode(content);
        return jsonData;
      } catch (err) {
        debugPrint(err.toString());
        return null;
      }
    }, data);
    return content;
  }

  static Future _wssDbRequest(
    SocketController? socket,
    WSSDataModel wss,
    EmbedModel embed,
  ) async {
    final database = await SharedPreferences.getInstance();
    String dbKey = "${embed.plugin.docId}-${wss.httpInfo.dbKey}";
    if (wss.httpInfo.dbMethod == WSSHttpDbMethod.get) {
      String? source = database.getString(dbKey);
      socket?.sendMessage(
        _responseWSSResult(
          wss,
          Response(source ?? "", source == null ? 404 : 200),
        ),
      );
    } else if (wss.httpInfo.dbMethod == WSSHttpDbMethod.set) {
      bool isSet = await database.setString(
        dbKey,
        wss.httpInfo.body.toString(),
      );
      socket?.sendMessage(
        _responseWSSResult(wss, Response("", isSet ? 200 : 500)),
      );
    } else if (wss.httpInfo.dbMethod == WSSHttpDbMethod.delete) {
      bool isDeleted = await database.remove(dbKey);
      socket?.sendMessage(
        _responseWSSResult(wss, Response("", isDeleted ? 200 : 500)),
      );
    }
  }

  static Future _wssHttpRequest(
    SocketController? socket,
    WSSDataModel wss,
  ) async {
    var client = HTTPRequest();
    Future<Response> future;
    if (wss.httpInfo.api == WSSFetchApiType.axios) {
      future = client.axios(
        wss.httpInfo,
        timeout: Duration(seconds: wss.httpInfo.timeout),
      );
    } else {
      future = client.request(wss.httpInfo);
    }
    final response = await future.timeout(
      Duration(seconds: wss.httpInfo.timeout),
      onTimeout: () async => Response("Error connection timeout.", 408),
    );
    socket?.sendMessage(_responseWSSResult(wss, response));
  }

  static Response _errorResponse(int status, String message) {
    return Response(
      json.encode({"status": status, "message": message}),
      status,
    );
  }

  static _checkJSON(String body) {
    try {
      return json.decode(body);
    } catch (e) {
      return body;
    }
  }

  static String _responseWSSResult(WSSDataModel data, Response resp) {
    bool isBytes = data.httpInfo.isResponseBytes;
    final body = isBytes ? resp.bodyBytes.toList() : _checkJSON(resp.body);
    final responseInfo = json.encode(
      WSSDataModel(
        action: WSSAction.result,
        id: data.id,
        data: {
          "status": resp.statusCode,
          "headers": resp.headers,
          "body": body,
        },
      ).toMap(),
    );
    return responseInfo;
  }
}
