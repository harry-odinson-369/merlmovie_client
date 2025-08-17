import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/global/global.vars.dart';
import 'package:merlmovie_client/src/models/cast_action.dart';
import 'package:merlmovie_client/src/controllers/socket.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';
import 'package:merlmovie_client/src/models/cast_info.dart';
import 'package:merlmovie_client/src/models/cast_landing.dart';
import 'package:merlmovie_client/src/models/cast_loading.dart';
import 'package:merlmovie_client/src/models/cast_player_value.dart';
import 'package:merlmovie_client/src/models/cast_subtitle.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/models/subtitle.dart';
import 'package:merlmovie_client/src/widgets/await_dialog.dart';
import 'package:merlmovie_client/src/widgets/hyperlink.dart';
import 'package:merlmovie_client/src/widgets/player_video_builder.dart';
import 'package:merlmovie_client/src/widgets/prompt_dialog.dart';
import 'package:wifi_address_helper/wifi_address_helper.dart';

class CastClientController {
  CastClientController._();

  static final CastClientController _instance = CastClientController._();
  static CastClientController get instance => _instance;

  String? notice;

  int port = 3679;
  String hostname = "";

  SocketController? _controller;

  Stream<dynamic>? get onMessage => _controller?.onMessage;
  Stream<dynamic>? get onError => _controller?.onError;
  Stream<dynamic>? get onClosed => _controller?.onClosed;

  final ValueNotifier<bool> _isConnected = ValueNotifier(false);
  ValueNotifier<bool> get isConnected => _isConnected;

  final ValueNotifier<VideoPlayerValueModel> _status = ValueNotifier(
    VideoPlayerValueModel.fromMap({}),
  );
  ValueNotifier<VideoPlayerValueModel> get status => _status;

  CastDeviceInfo? _castDeviceInfo;
  CastDeviceInfo? get castDeviceInfo => _castDeviceInfo;

  LandingModel? _landing;
  LandingModel? get landing => _landing;

  Future connect() async {
    String? adr = await WifiAddressHelper.getAddress;
    if (adr != null) {
      final split = adr.split(".")..removeLast();
      final arr = [1, 21, 41, 61, 81, 100];
      for (int el in arr) {
        var futures = List.generate(20, (index) {
          final ip = [...split, "${el + index}"].join(".");
          return _findSocket(ip);
        });
        final results = await Future.wait(futures);
        int index = results.indexWhere((e) => e != null);
        if (index != -1) {
          _controller = results[index];
          _castDeviceInfo = await _connectToDevice(_controller!);
          _isConnected.value = _castDeviceInfo != null;
          _controller?.onMessage?.listen(_onStatusChanged);
          _controller?.onError?.listen(_onError);
          _controller?.onClosed?.listen(_onClosed);
          hostname = [...split, "${index + 1}"].join(".");
          break;
        }
      }
    }
  }

  Future<bool?> toggleConnect({
    String? notice,
    List<Widget>? noticeButtons,
    bool showOnError = false,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    Color? backgroundColor,
    Brightness? cupertinoBrightness,
    TextStyle? negativeButtonTextStyle,
    TextStyle? positiveButtonTextStyle,
  }) async {
    if (isConnected.value) {
      bool ok = await showPromptDialog(
        title:
            "Are you want to disconnect from ${_castDeviceInfo?.deviceName ?? "Broadcast"}?",
        backgroundColor: backgroundColor,
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        positiveButtonTextStyle: positiveButtonTextStyle,
        negativeButtonTextStyle: negativeButtonTextStyle,
        cupertinoBrightness: cupertinoBrightness,
      );
      if (ok) {
        await disconnect();
        return _isConnected.value;
      }
    } else {
      if (notice != null) {
        this.notice = notice;
      }
      if (this.notice != null) {
        await showDialog(
          context: NavigatorKey.currentContext!,
          builder: (context) {
            return AlertDialog(
              backgroundColor: backgroundColor ?? Colors.grey.shade800,
              title: Text("Notice", style: titleStyle),
              content: SizedBox(
                width: context.maxMobileWidth,
                child: ExpandCollapseText(
                  text: this.notice!,
                  collapsedMaxLines: 15,
                  textAlign: TextAlign.start,
                  style: subtitleStyle,
                ),
              ),
              actions:
                  noticeButtons ??
                  [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "OK",
                        style:
                            positiveButtonTextStyle ??
                            context.theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
            );
          },
        );
      }
      bool ok = await showPromptDialog(
        title: "Are you want to broadcast to TV?",
        cupertinoBrightness: cupertinoBrightness,
        backgroundColor: backgroundColor,
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        positiveButtonTextStyle: positiveButtonTextStyle,
        negativeButtonTextStyle: negativeButtonTextStyle,
      );
      if (ok) {
        await showAwaitingDialog(
          connect,
          label: "Connecting...",
          backgroundColor: backgroundColor,
          labelColor: subtitleStyle?.color,
          cupertinoBrightness: cupertinoBrightness,
        );
        if (showOnError) {
          if (_isConnected.value == false) {
            await showPromptDialog(
              title: "Error",
              subtitle:
                  "We couldn't find the [Media Receiver](https://play.google.com/store/apps/details?id=com.NOUVANNET.scanner) on your local network! Please make sure your phone and TV are connected to the same Wi-Fi network, and ensure the [Media Receiver](https://play.google.com/store/apps/details?id=com.NOUVANNET.scanner) app is open on your TV.",
              button: PromptDialogButton.ok,
              backgroundColor: backgroundColor,
              titleStyle: titleStyle,
              subtitleStyle: subtitleStyle,
              positiveButtonTextStyle: positiveButtonTextStyle,
              negativeButtonTextStyle: negativeButtonTextStyle,
              cupertinoBrightness: cupertinoBrightness,
            );
          }
        }
        return _isConnected.value;
      }
    }
    return null;
  }

  Future disconnect() async {
    _controller?.sendMessage(
      ServerAction(action: ActionServer.disconnect).encoded,
    );
    await _controller?.close();
    _controller = null;
    _isConnected.value = false;
    _castDeviceInfo = null;
    _status.value = VideoPlayerValueModel.fromMap({});
  }

  void setLanding(LandingModel landing) {
    _landing = landing;
  }

  Future<bool> start(QualityItem quality) async {
    Completer<bool> completer = Completer<bool>();
    _status.value = VideoPlayerValueModel.fromMap({});
    _controller?.onMessage?.listen((event) {
      var msg = ServerAction.fromMap(json.decode(event.toString()));
      if (msg.action == ActionServer.video_loaded) {
        completer.finish(true);
      } else if (msg.action == ActionServer.video_error) {
        completer.finish(false);
      }
    });
    var theme = await SubtitleTheme.getTheme();
    subtitleTheme(theme);
    _controller?.sendMessage(
      ServerAction(
        action: ActionServer.start,
        payload: quality.toMap(),
      ).encoded,
    );
    return completer.future;
  }

  void play() {
    _controller?.sendMessage(ServerAction(action: ActionServer.play).encoded);
  }

  void pause() {
    _controller?.sendMessage(ServerAction(action: ActionServer.pause).encoded);
  }

  void forward() {
    _controller?.sendMessage(
      ServerAction(action: ActionServer.forward).encoded,
    );
  }

  void rewind() {
    _controller?.sendMessage(ServerAction(action: ActionServer.rewind).encoded);
  }

  void seek(Duration duration) {
    _controller?.sendMessage(
      ServerAction(
        action: ActionServer.seek,
        payload: {"position": duration.inSeconds},
      ).encoded,
    );
  }

  void speed(double value) {
    _controller?.sendMessage(
      ServerAction(
        action: ActionServer.playback_speed,
        payload: {"speed": value},
      ).encoded,
    );
  }

  void loading(LoadingModel model) async {
    _controller?.sendMessage(
      ServerAction(
        action: ActionServer.loading,
        payload: model.toMap(),
      ).encoded,
    );
  }

  void videoMode(VideoViewBuilderType viewType) {
    _controller?.sendMessage(
      ServerAction(
        action: ActionServer.video_mode,
        payload: {"mode": viewType.name},
      ).encoded,
    );
  }

  void subtitle(List<CastSubtitle> subtitles) {
    _controller?.sendMessage(
      ServerAction(
        action: ActionServer.subtitle,
        payload: {"subtitles": subtitles.map((e) => e.toMap()).toList()},
      ).encoded,
    );
  }

  void subtitleTheme(SubtitleTheme theme) {
    _controller?.sendMessage(
      ServerAction(
        action: ActionServer.subtitle_theme,
        payload: theme.toMap(),
      ).encoded,
    );
  }

  void idle() {
    _controller?.sendMessage(ServerAction(action: ActionServer.idle).encoded);
    _status.value = VideoPlayerValueModel.fromMap({});
  }

  void _onStatusChanged(dynamic event) {
    var msg = ServerAction.fromMap(json.decode(event.toString()));
    if (msg.action == ActionServer.status) {
      _status.value = VideoPlayerValueModel.fromMap(msg.payload);
    }
  }

  void _onClosed(dynamic _) {
    disconnect();
  }

  void _onError(dynamic err) {
    _isConnected.value = false;
    _castDeviceInfo = null;
    _controller?.close();
    _controller = null;
  }

  Future<CastDeviceInfo> _connectToDevice(SocketController socket) async {
    Completer<CastDeviceInfo> completer = Completer();
    socket.onMessage?.listen((event) {
      var msg = ServerAction.fromMap(json.decode(event.toString()));
      if (msg.action == ActionServer.connected) {
        completer.finish(CastDeviceInfo.fromMap(msg.payload));
      }
    });
    socket.sendMessage(
      ServerAction(
        action: ActionServer.connect,
        payload: _landing?.toMap() ?? {},
      ).encoded,
    );
    return completer.future;
  }

  Future<SocketController?> _findSocket(String ip) async {
    try {
      var controller = SocketController(
        "ws://$ip:$port",
        timeout: Duration(seconds: 1),
      );
      bool? res = await controller.ready;
      if (res == true) return controller;
      return null;
    } catch (_) {
      return null;
    }
  }
}
