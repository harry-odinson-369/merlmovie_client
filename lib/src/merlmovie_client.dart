import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_auto_admob/flutter_auto_admob.dart';
import 'package:http/http.dart';
import 'package:merlmovie_client/src/controllers/socket_controller.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';
import 'package:merlmovie_client/src/extensions/global_key.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/global/global.vars.dart';
import 'package:merlmovie_client/src/helpers/http.dart';
import 'package:merlmovie_client/src/helpers/information.dart';
import 'package:merlmovie_client/src/helpers/logger.dart';
import 'package:merlmovie_client/src/helpers/themoviedb.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/models/callback.dart';
import 'package:merlmovie_client/src/models/plugin.dart';
import 'package:merlmovie_client/src/models/wss.dart';
import 'package:merlmovie_client/src/providers/browser.dart';
import 'package:merlmovie_client/src/widgets/browser.dart';
import 'package:merlmovie_client/src/widgets/player.dart';
import 'package:merlmovie_client/src/widgets/webview.dart';
import 'package:merlmovie_client/src/widgets/webview_player.dart';
import 'package:merlmovie_client/src/widgets/wss_select_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

SocketController? _controller;
FlutterAutoAdmobConfig? _autoAdmobConfig;

class MerlMovieClient {
  static SocketController? get socket => _controller;

  static bool get isPlayerActive => NavigatorKey.isPlayerActive;

  static FlutterAutoAdmobConfig? get adConfig => _autoAdmobConfig;

  static void setAdConfig(FlutterAutoAdmobConfig? config) {
    _autoAdmobConfig = config;
    _autoAdmobConfig?.interstitialAdLoadType = FlutterAutoAdmobLoadType.none;
  }

  static Future closeWSSConnection() async {
    await _controller?.close();
    _controller = null;
    NavigatorKey.currentContext?.read<BrowserProvider>().close();
  }

  static Future<DirectLink?> request(
    EmbedModel embed, {
    void Function(int status, String message)? onError,
    void Function(double progress)? onProgress,
  }) async {
    DirectLink? directLink;
    try {
      directLink = await _request(embed, onProgress: onProgress);
    } catch (_) {}
    directLink ??= await _request(
      embed,
      onProgress: onProgress,
      onError: onError,
    );
    return directLink;
  }

  static Future<DirectLink?> _request(
    EmbedModel embed, {
    void Function(int status, String message)? onError,
    void Function(double progress)? onProgress,
  }) async {
    Response response;

    LoggerHelper.logMsg("Requesting to target ${embed.request_url}...");

    String requestUrl = await InformationHelper.requestUrlWithXCI(
      embed.request_url,
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
        try {
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
            NavigatorKey.currentContext?.read<BrowserProvider>().close();
            completer.finish(Response(json.encode(wss.data), 200));
          } else if (wss.action == WSSAction.failed) {
            completer.finish(
              Response(json.encode(wss.data), wss.data["status"]),
            );
          } else if (wss.action == WSSAction.browser) {
            NavigatorKey.currentContext?.read<BrowserProvider>().spawn(
              wss.browserInfo,
            );
          } else if (wss.action == WSSAction.browser_close) {
            NavigatorKey.currentContext?.read<BrowserProvider>().close();
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
            NavigatorKey.currentContext?.read<BrowserProvider>().visible(
              wss.visible,
            );
          } else if (wss.action == WSSAction.select) {
            WSSSelectModel? selected = await showWSSSelectDialog(
              List<WSSSelectModel>.from(
                (wss.data["items"] ?? []).map((e) {
                  return WSSSelectModel.fromMap(e);
                }),
              ),
            );
            final data = WSSDataModel(
              action: WSSAction.select_result,
              id: wss.id,
              data: {"result": selected?.toMap()},
            );
            socket?.sendMessage(json.encode(data.toMap()));
          }
        } catch (_) {}
      }

      socket?.message?.listen(handler);

      final mediaInfo = {
        "media_type": embed.type,
        "media_id": embed.plugin.useIMDb ? embed.imdbId : embed.tmdbId,
        "season_id": embed.season,
        "episode_id": embed.episode,
        "data": embed.detail.toJson(),
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

  static void setTheMovieDbApiKeys(List<String> keys) =>
      TheMovieDbApi.setApiKeys(keys);

  static EmbedModel create_embed(
    PluginModel selected,
    DetailModel detail, [
    Episode? episode,
  ]) {
    return EmbedModel(
      plugin: selected,
      detail: detail,
      tmdbId: detail.id.toString(),
      type: detail.type,
      imdbId: detail.externalIds.imdbId,
      season: episode?.seasonNumber.toString() ?? "",
      episode: episode?.episodeNumber.toString() ?? "",
      title: detail.real_title,
      thumbnail: TheMovieDbApi.getImage(
        episode != null ? episode.stillPath : detail.backdropPath,
        TMDBImageSize.original,
      ),
      title_logo: TheMovieDbApi.getImage(
        detail.real_title_logo,
        TMDBImageSize.w300,
      ),
    );
  }

  static Future open(
    EmbedModel embed, {
    List<PluginModel> plugins = const [],
    MerlMovieClientPlayerCallback? callback,
    String? selectPluginSheetLabel,
    Duration initialPosition = Duration.zero,
    List<DeviceOrientation>? onDisposedDeviceOrientations,
    Future<DetailModel> Function(MovieModel movie)? onRequestDetail,
    Future<DirectLink> Function(DirectLink link, EmbedModel embed)?
    onDirectLinkRequested,
    bool pushReplacement = false,
  }) async {
    var playerPlugins =
        plugins.where((e) {
          return e.openType != PluginOpenType.webview;
        }).toList();
    var filtered_plugins = [
      embed.plugin,
      ...[
        ...playerPlugins.where((e) => e.useInternalPlayer),
        ...playerPlugins.where((e) => e.useWebView),
      ].where((e) => e != embed.plugin),
    ];
    bool isAddSimilar = onRequestDetail != null;
    var similar = <MovieModel>[
      if (isAddSimilar) ...embed.detail.recommendations.results,
      if (isAddSimilar) ...embed.detail.similar.results,
    ];

    if (embed.plugin.openType == PluginOpenType.player) {
      if (embed.plugin.useWebView) {
        var route = MaterialPageRoute(
          builder: (context) {
            return Theme(
              data: ThemeData.dark(),
              child: MerlMovieClientWebViewPlayer(
                embed: embed,
                similar: similar,
                callback: callback,
                plugins: filtered_plugins,
                onRequestDetail: onRequestDetail,
                onDirectLinkRequested: onDirectLinkRequested,
                selectPluginSheetLabel: selectPluginSheetLabel,
                onDisposedDeviceOrientations: onDisposedDeviceOrientations,
              ),
            );
          },
        );
        if (pushReplacement) {
          return await Navigator.of(
            NavigatorKey.currentContext!,
          ).pushReplacement(route);
        } else {
          return await Navigator.of(NavigatorKey.currentContext!).push(route);
        }
      } else if (embed.plugin.useInternalPlayer) {
        var route = MaterialPageRoute(
          builder: (context) {
            return Theme(
              data: ThemeData.dark(),
              child: MerlMovieClientPlayer(
                embed: embed,
                similar: similar,
                callback: callback,
                seasons: embed.detail.seasons,
                plugins: filtered_plugins,
                initialPosition: initialPosition,
                onRequestDetail: onRequestDetail,
                onDirectLinkRequested: onDirectLinkRequested,
                selectPluginSheetLabel: selectPluginSheetLabel,
                onDisposedDeviceOrientations: onDisposedDeviceOrientations,
              ),
            );
          },
        );
        if (pushReplacement) {
          Navigator.of(NavigatorKey.currentContext!).pushReplacement(route);
        } else {
          Navigator.of(NavigatorKey.currentContext!).push(route);
        }
      }
    } else if (embed.plugin.openType == PluginOpenType.webview) {
      Navigator.of(NavigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (context) {
            return MerlMovieClientWebViewWidget(link: embed.request_url);
          },
        ),
      );
    }
  }
}
