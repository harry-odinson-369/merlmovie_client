import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/seasons.dart';
import 'package:merlmovie_client/src/helpers/subtitle.dart';
import 'package:merlmovie_client/src/helpers/themoviedb.dart';
import 'package:merlmovie_client/src/merlmovie_client.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/models/player_config.dart';
import 'package:merlmovie_client/src/models/plugin.dart';
import 'package:merlmovie_client/src/widgets/player_bottom_controls.dart';
import 'package:merlmovie_client/src/widgets/player_display_caption.dart';
import 'package:merlmovie_client/src/widgets/player_loading.dart';
import 'package:merlmovie_client/src/widgets/player_middle_controls.dart';
import 'package:merlmovie_client/src/widgets/player_top_controls.dart';
import 'package:merlmovie_client/src/widgets/player_video_builder.dart';
import 'package:merlmovie_client/src/widgets/prompt_dialog.dart';
import 'package:merlmovie_client/src/widgets/player_select_plugin.dart';
import 'package:subtitle/subtitle.dart';
import 'package:video_player/video_player.dart';

bool _isActive = false;

class MerlMovieClientPlayer extends StatefulWidget {
  final EmbedModel embed;
  final MerlMovieClientPlayerCallback? callback;
  final List<DeviceOrientation>? onDisposedDeviceOrientations;
  final List<PluginModel> plugins;
  final Duration initialPosition;
  final List<Season> seasons;
  final String? selectPluginSheetLabel;
  const MerlMovieClientPlayer({
    super.key,
    required this.embed,
    this.callback,
    this.onDisposedDeviceOrientations,
    this.plugins = const [],
    this.seasons = const [],
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
        return PlayerSelectPlugin(plugins: plugins, label: label, embed: embed);
      },
    );
    return plugin;
  }

  @override
  State<MerlMovieClientPlayer> createState() => _MerlMovieClientPlayerState();
}

class _MerlMovieClientPlayerState extends State<MerlMovieClientPlayer> {
  MerlMovieClientPlayerCallback get config =>
      widget.callback ?? MerlMovieClientPlayerCallback();

  Duration position = Duration.zero;

  double progress = 0;

  ValueNotifier<bool> hideControls = ValueNotifier<bool>(false);

  double playbackSpeed = 1.0;

  SubtitleItem? subtitle;

  ValueNotifier<List<Subtitle>> subtitles = ValueNotifier([]);

  VideoPlayerController? controller;
  DirectLink? directLink;

  QualityItem? currentQuality;

  ValueNotifier<VideoViewBuilderType> videoViewType = ValueNotifier(
    VideoViewBuilderType.cropToFit,
  );

  Timer? _hideControlsTimer;

  void update() => mounted ? setState(() {}) : () {};

  Future initialize() async {
    await controller?.dispose();
    directLink = null;
    progress = 0;
    update();
    directLink = await MerlMovieClient.request(
      widget.embed,
      onProgress: onRequestProgress,
      onError: widget.plugins.isEmpty ? onRequestError : null,
    );
    if (directLink == null) {
      for (int i = 0; i < widget.plugins.length; i++) {
        if (mounted) {
          widget.embed.plugin = widget.plugins[i];
          update();
          directLink = await MerlMovieClient.request(
            widget.embed,
            onProgress: onRequestProgress,
            onError: (i + 1) >= widget.plugins.length ? onRequestError : null,
          );
        }
      }
    }
    update();
    if (mounted && directLink != null) {
      for (int i = 0; i < directLink!.qualities.length; i++) {
        final qua = directLink!.qualities[i];
        bool isLoaded = await changeQuality(
          qua,
          (i + 1) >= directLink!.qualities.length,
        );
        if (isLoaded) {
          break;
        }
      }
    }
  }

  Future<bool> changeQuality(
    QualityItem quality, [
    bool showError = false,
  ]) async {
    if (currentQuality?.link != quality.link) {
      try {
        await controller?.dispose();
        controller = null;
        currentQuality = quality;
        controller = VideoPlayerController.networkUrl(
          Uri.parse(quality.link),
          httpHeaders: quality.headers ?? {},
        );
        hideControls.value = false;
        update();
        await controller?.initialize();
        controller?.addListener(playerListener);
        update();
        await controller?.seekTo(position);
        controller?.play().then((value) {
          hideControls.value = true;
        });
        update();
        return true;
      } catch (err) {
        if (showError) {
          onLoadError("Player error", "${err.toString()}\n");
        }
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

  Future onLoadError(String title, String message) async {
    bool? accepted = await showPromptDialog(
      context,
      title: title,
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
    update();
    initialize();
  }

  void onViewTypeChanged(VideoViewBuilderType type) {
    videoViewType.value = type;
  }

  void onPlaybackSpeedChanged(double speed) {
    playbackSpeed = speed;
    controller?.setPlaybackSpeed(speed);
    update();
  }

  void onQualityChanged(QualityItem quality) {
    changeQuality(quality, true);
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

  Future onEpisodeChanged(Episode episode) async {
    if (episode.seasonNumber != int.parse(widget.embed.season!) ||
        episode.episodeNumber != int.parse(widget.embed.episode!)) {
      widget.embed.season = episode.seasonNumber.toString();
      widget.embed.episode = episode.episodeNumber.toString();
      widget.embed.thumbnail = TheMovieDbApi.getImage(episode.stillPath);
      position = Duration.zero;
      subtitle?.children = [];
      subtitle?.real_link = null;
      subtitles.value = [];
      update();
      initialize();
    }
  }

  Future onSubtitleChanged(SubtitleItem subtitle) async {
    if (subtitle != this.subtitle) {
      this.subtitle = subtitle;
      update();
      List<Subtitle> arr = await compute((subtitle) async {
        bool isFetch = subtitle.type == SubtitleRootType.fetch;
        String link = subtitle.real_link ?? subtitle.link;
        return await SubtitleHelper.fromNetwork(
          Uri.parse(link),
          headers: subtitle.headers,
          extension:
              isFetch
                  ? (subtitle.key?.extension ?? SubtitleFetchExtension.text)
                  : SubtitleFetchExtension.text,
        );
      }, subtitle);
      subtitles.value = arr;
    }
  }

  void showHideControls() {
    hideControls.value = !hideControls.value;
    preventHideControls();
  }

  void preventHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      hideControls.value = true;
    });
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
      body: GestureDetector(
        onTap: showHideControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: context.screen.height,
              width: context.screen.width,
            ),
            if (directLink != null && controller != null)
              PlayerVideoBuilder(
                controller: controller,
                viewType: videoViewType,
              ),
            if (controller != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: context.screen.height * .1,
                child: ValueListenableBuilder(
                  valueListenable: subtitles,
                  builder: (context, items, child) {
                    if (items.isEmpty) {
                      return SizedBox();
                    }
                    return PlayerDisplayCaption(
                      subtitles: items,
                      controller: controller,
                    );
                  },
                ),
              ),
            if (directLink != null && controller != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: ValueListenableBuilder(
                  valueListenable: hideControls,
                  builder: (context, isHiding, _) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child:
                          isHiding
                              ? SizedBox(key: UniqueKey())
                              : Container(
                                key: UniqueKey(),
                                color: Colors.black.withOpacity(.7),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    PlayerTopControls(
                                      embed: widget.embed,
                                      controller: controller,
                                      onTrailingClicked:
                                          widget.plugins.isNotEmpty
                                              ? onTrailingClicked
                                              : null,
                                      trailing:
                                          widget.plugins.isNotEmpty
                                              ? Icon(
                                                Icons.format_list_bulleted,
                                                color: Colors.white,
                                              )
                                              : null,
                                      preventHideControls: preventHideControls,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 24),
                                      child: PlayerMiddleControls(
                                        controller: controller,
                                        preventHideControls:
                                            preventHideControls,
                                      ),
                                    ),
                                    PlayerBottomControls(
                                      controller: controller,
                                      currentViewType: videoViewType,
                                      currentPlaybackSpeed: playbackSpeed,
                                      currentQuality: currentQuality,
                                      currentEpisode: widget.seasons
                                          .findCurrentEpisode(widget.embed),
                                      qualities: directLink?.qualities ?? [],
                                      seasons: widget.seasons,
                                      currentSubtitle: subtitle,
                                      subtitles: directLink?.subtitles ?? [],
                                      onPlaybackSpeedChanged:
                                          onPlaybackSpeedChanged,
                                      onViewTypeChanged: onViewTypeChanged,
                                      onQualityChanged: onQualityChanged,
                                      onEpisodeChanged: onEpisodeChanged,
                                      onSubtitleChanged: onSubtitleChanged,
                                      preventHideControls: preventHideControls,
                                    ),
                                  ],
                                ),
                              ),
                    );
                  },
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
      ),
    );
  }
}
