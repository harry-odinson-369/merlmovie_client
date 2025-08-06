import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/cast_receiver/apis/server.dart';
import 'package:merlmovie_client/src/cast_receiver/models/action.dart';
import 'package:merlmovie_client/src/cast_receiver/models/loading.dart';
import 'package:merlmovie_client/src/cast_receiver/models/player_value.dart';
import 'package:merlmovie_client/src/cast_receiver/models/subtitle.dart';
import 'package:merlmovie_client/src/cast_receiver/widgets/landing_board.dart';
import 'package:merlmovie_client/src/cast_receiver/widgets/switch.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/models/subtitle.dart';
import 'package:merlmovie_client/src/widgets/player_display_caption.dart';
import 'package:merlmovie_client/src/widgets/player_over_loading.dart';
import 'package:merlmovie_client/src/widgets/player_video_builder.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class LandingReceiver extends StatefulWidget {
  const LandingReceiver({super.key});

  @override
  State<LandingReceiver> createState() => _LandingReceiverState();
}

class _LandingReceiverState extends State<LandingReceiver> {
  bool isServing = false;

  ValueNotifier<VideoViewBuilderType> viewType = ValueNotifier(
    VideoViewBuilderType.crop,
  );

  WebSocket? socket;

  VideoPlayerController? controller;

  QualityItem? quality;
  LoadingModel? loading;

  ValueNotifier<List<CastSubtitle>> subtitles = ValueNotifier([]);

  ValueNotifier<SubtitleTheme> subtitleTheme = ValueNotifier(
    SubtitleTheme.fromMap({}),
  );

  void update() => mounted ? setState(() {}) : () {};

  Timer? _statusTimer;

  void sendStatus() {
    if (controller != null) {
      socket?.add(
        json.encode(
          ServerAction(
            action: ActionServer.status,
            payload: VideoPlayerValueModel.parse(controller!).toMap(),
          ).toMap(),
        ),
      );
    }
  }

  Future<bool> startPlay() async {
    _statusTimer?.cancel();
    _statusTimer = null;
    await controller?.dispose();
    controller = null;
    update();
    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(quality!.link),
        httpHeaders: quality!.headers ?? {},
      );
      update();
      await controller?.initialize();
      controller?.play();
      _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        sendStatus();
      });
      update();
      return true;
    } catch (_) {
      return false;
    }
  }

  void handle(ServerAction msg, WebSocket socket) {
    this.socket = socket;
    if (msg.action == ActionServer.idle ||
        msg.action == ActionServer.disconnect) {
      quality = null;
      loading = null;
      subtitles.value = [];
      controller?.dispose();
      _statusTimer?.cancel();
      _statusTimer = null;
      if (msg.action == ActionServer.disconnect) {
        ServerControl.instance.landing.value = LandingModel();
      }
      update();
    } else if (msg.action == ActionServer.loading) {
      controller?.dispose();
      controller = null;
      quality = null;
      loading = LoadingModel.fromMap(msg.payload);
      update();
    } else if (msg.action == ActionServer.start) {
      loading = null;
      subtitles.value = [];
      quality = QualityItem.fromMap(msg.payload);
      startPlay().then((loaded) {
        socket.add(
          ServerAction(
            action:
                loaded ? ActionServer.video_loaded : ActionServer.video_error,
          ).encoded,
        );
      });
      update();
    } else if (msg.action == ActionServer.pause) {
      controller?.pause();
    } else if (msg.action == ActionServer.play) {
      controller?.play();
    } else if (msg.action == ActionServer.forward) {
      controller?.seekTo(
        Duration(seconds: controller!.value.position.inSeconds + 15),
      );
    } else if (msg.action == ActionServer.rewind) {
      controller?.seekTo(
        Duration(seconds: controller!.value.position.inSeconds - 15),
      );
    } else if (msg.action == ActionServer.seek) {
      controller?.seekTo(Duration(seconds: msg.payload["position"]));
    } else if (msg.action == ActionServer.video_mode) {
      viewType.value = VideoViewBuilderType.values.firstWhere(
        (e) => e.name == msg.payload["mode"],
      );
    } else if (msg.action == ActionServer.playback_speed) {
      controller?.setPlaybackSpeed(msg.payload["speed"]);
    } else if (msg.action == ActionServer.subtitle) {
      subtitles.value = List<CastSubtitle>.from(
        (msg.payload["subtitles"] ?? []).map((e) => CastSubtitle.fromMap(e)),
      );
    } else if (msg.action == ActionServer.subtitle_theme) {
      subtitleTheme.value = SubtitleTheme.fromMap(msg.payload);
    }
  }

  @override
  void initState() {
    WakelockPlus.enable();
    ServerControl.instance.listen(
      handle,
      onBind: (server) {
        isServing = true;
        update();
      },
      onCreated: (socket) {
        this.socket = socket;
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    controller = null;
    socket?.close();
    socket = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ServerControl.instance.landing,
      builder: (context, landing, _) {
        return Scaffold(
          backgroundColor: landing.backgroundColor,
          body: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              switchInCurve: Curves.linear,
              child: FadeSwitchOnBool(
                showSecond: isServing,
                first: CircularProgressIndicator(
                  key: UniqueKey(),
                  color: landing.appNameColor,
                ),
                second: Builder(
                  builder: (context) {
                    if (quality != null && controller != null) {
                      if (controller!.value.isBuffering ||
                          !controller!.value.isInitialized) {
                        return CircularProgressIndicator(color: Colors.white70);
                      }
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          PlayerVideoBuilder(
                            controller: controller!,
                            viewType: viewType,
                          ),
                          ValueListenableBuilder(
                            valueListenable: subtitleTheme,
                            builder: (context, currentSubtitleTheme, _) {
                              return Positioned(
                                left: 12,
                                right: 12,
                                bottom: currentSubtitleTheme.bottomPad,
                                child: ValueListenableBuilder(
                                  valueListenable: subtitles,
                                  builder: (context, items, child) {
                                    if (items.isEmpty) {
                                      return SizedBox();
                                    }
                                    return PlayerDisplayCaption(
                                      subtitles: items,
                                      controller: controller,
                                      subtitleTheme: currentSubtitleTheme,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    } else if (loading != null) {
                      return PlayerOverLoading(
                        progress: loading!.progress.toInt(),
                        embed: loading!.embed,
                      );
                    } else {
                      return LandingBoard(model: landing);
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
