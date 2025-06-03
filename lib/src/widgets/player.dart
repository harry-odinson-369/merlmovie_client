import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/merlmovie_client.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/models/player_config.dart';
import 'package:merlmovie_client/src/models/plugin.dart';
import 'package:merlmovie_client/src/widgets/player_bottom_controls.dart';
import 'package:merlmovie_client/src/widgets/player_bottom_controls_button.dart';
import 'package:merlmovie_client/src/widgets/player_loading.dart';
import 'package:merlmovie_client/src/widgets/player_middle_controls.dart';
import 'package:merlmovie_client/src/widgets/player_top_controls.dart';
import 'package:merlmovie_client/src/widgets/player_video_builder.dart';
import 'package:merlmovie_client/src/widgets/prompt_dialog.dart';
import 'package:merlmovie_client/src/widgets/select_plugins.dart';
import 'package:video_player/video_player.dart';

bool _isActive = false;

class MerlMovieClientPlayer extends StatefulWidget {
  final EmbedModel embed;
  final MerlMovieClientPlayerConfig? config;
  final List<DeviceOrientation>? onDisposedDeviceOrientations;
  final List<PluginModel> plugins;
  final Duration initialPosition;
  final List<Episode> episodes;
  final List<PlayerBottomControlsButton> Function(
    List<PlayerBottomControlsButton> buttons,
  )?
  buttons;
  final String? selectPluginSheetLabel;
  const MerlMovieClientPlayer({
    super.key,
    required this.embed,
    this.config,
    this.onDisposedDeviceOrientations,
    this.buttons,
    this.plugins = const [],
    this.episodes = const [],
    this.selectPluginSheetLabel,
    this.initialPosition = Duration.zero,
  });

  static bool get isActive => _isActive;

  static void setDeviceOrientationAndSystemUI() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  static void restoreDeviceOrientationAndSystemUI([
    List<DeviceOrientation>? orientations,
  ]) {
    SystemChrome.setPreferredOrientations(
      orientations ??
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  static Future<PluginModel?> selectPlugin(
    BuildContext context,
    List<PluginModel> plugins,
    EmbedModel embed, {
    String? label,
  }) async {
    PluginModel? plugin = await showModalBottomSheet<PluginModel?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SelectPlugins(plugins: plugins, label: label, embed: embed);
      },
    );
    return plugin;
  }

  @override
  State<MerlMovieClientPlayer> createState() => _MerlMovieClientPlayerState();
}

class _MerlMovieClientPlayerState extends State<MerlMovieClientPlayer> {
  MerlMovieClientPlayerConfig get config =>
      widget.config ?? MerlMovieClientPlayerConfig();

  Duration position = Duration.zero;

  double progress = 0;

  double playbackSpeed = 1.0;

  VideoPlayerController? controller;
  DirectLink? directLink;

  QualityItem? currentQuality;

  VideoViewType videoViewType = VideoViewType.original;

  void update() => mounted ? setState(() {}) : () {};

  Future initialize() async {
    await controller?.dispose();
    directLink = null;
    progress = 0;
    update();
    directLink = await MerlMovieClient.request(
      widget.embed,
      onProgress: onRequestProgress,
      onError: onRequestError,
    );
    update();
    if (mounted && directLink != null) {
      for (final qua in directLink!.qualities) {
        bool isLoaded = await changeQuality(qua);
        if (isLoaded) {
          break;
        }
      }
    }
  }

  Future<bool> changeQuality(QualityItem quality) async {
    if (currentQuality?.link != quality.link) {
      try {
        await controller?.dispose();
        controller = null;
        currentQuality = quality;
        update();
        controller = VideoPlayerController.networkUrl(
          Uri.parse(quality.link),
          httpHeaders: quality.headers ?? {},
        );
        await controller?.initialize();
        controller?.addListener(playerListener);
        update();
        await controller?.seekTo(position);
        controller?.play();
        update();
        return true;
      } catch (err) {
        return false;
      }
    } else {
      return true;
    }
  }

  void playerListener() {
    if (controller != null) {
      config.onPositionChanged?.call(
        controller!.value.position,
        controller!.value.duration,
      );
      position = controller!.value.position;
    }
  }

  void onRequestProgress(double progress) {
    this.progress = progress;
    update();
  }

  Future onRequestError(int status, String message) async {
    bool? accepted = await showPromptDialog(
      context,
      title: "Error code $status",
      subtitle:
          "$message${widget.plugins.isNotEmpty ? "\nWould you like to change the source?" : ""}",
    );
    if (accepted) {
      if (mounted) {
        PluginModel? plugin = await MerlMovieClientPlayer.selectPlugin(
          context,
          widget.plugins,
          widget.embed,
          label: widget.selectPluginSheetLabel,
        );
        if (plugin != null) {
          onPluginChanged(plugin);
        }
      }
    }
  }

  void onPluginChanged(PluginModel plugin) {
    widget.embed.plugin = plugin;
    initialize();
  }

  void onViewTypeChanged(VideoViewType type) {
    videoViewType = type;
    update();
  }

  void onPlaybackSpeedChanged(double speed) {
    playbackSpeed = speed;
    controller?.setPlaybackSpeed(speed);
    update();
  }

  void onQualityChanged(QualityItem quality) {
    changeQuality(quality);
  }

  Future onTrailingClicked() async {
    PluginModel? plugin = await MerlMovieClientPlayer.selectPlugin(
      context,
      widget.plugins,
      widget.embed,
      label: widget.selectPluginSheetLabel,
    );
    if (plugin != null) {
      onPluginChanged(plugin);
    }
  }

  @override
  void initState() {
    super.initState();
    _isActive = true;
    position = widget.initialPosition;
    MerlMovieClientPlayer.setDeviceOrientationAndSystemUI();
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
    _isActive = false;
    MerlMovieClientPlayer.restoreDeviceOrientationAndSystemUI(
      widget.onDisposedDeviceOrientations,
    );
    MerlMovieClient.closeWSSConnection();
    if (controller != null) {
      if (controller!.value.position.inMinutes >=
          (controller!.value.duration.inMinutes - 10)) {
        config.onDecideAsWatched?.call();
      }
    }
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: 0,
        leadingWidth: 0,
        leading: SizedBox(),
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.black,
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(height: context.screen.height, width: context.screen.width),
          if (directLink != null && controller != null)
            PlayerVideoBuilder(controller: controller, viewType: videoViewType),
          if (directLink != null && controller != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(.7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PlayerTopControls(
                      embed: widget.embed,
                      controller: controller,
                      onTrailingClicked: onTrailingClicked,
                      trailing: Icon(
                        Icons.format_list_bulleted,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: PlayerMiddleControls(controller: controller),
                    ),
                    PlayerBottomControls(
                      controller: controller,
                      buttons: widget.buttons,
                      viewType: videoViewType,
                      playbackSpeed: playbackSpeed,
                      quality: currentQuality,
                      qualities: directLink?.qualities ?? [],
                      episodes: widget.episodes,
                      onPlaybackSpeedChanged: onPlaybackSpeedChanged,
                      onViewTypeChanged: onViewTypeChanged,
                      onQualityChanged: onQualityChanged,
                    ),
                  ],
                ),
              ),
            ),
          if (directLink == null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: PlayerLoading(
                embed: widget.embed,
                progress: progress,
                plugins: widget.plugins,
                sheetLabel: widget.selectPluginSheetLabel,
                onPluginChanged: onPluginChanged,
              ),
            ),
        ],
      ),
    );
  }
}
