// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_auto_admob/flutter_auto_admob.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/seasons.dart';
import 'package:merlmovie_client/src/global/global.vars.dart';
import 'package:merlmovie_client/src/helpers/proxy.dart';
import 'package:merlmovie_client/src/helpers/subtitle.dart';
import 'package:merlmovie_client/src/helpers/themoviedb.dart';
import 'package:merlmovie_client/src/merlmovie_client.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/models/callback.dart';
import 'package:merlmovie_client/src/models/plugin.dart';
import 'package:merlmovie_client/src/models/subtitle.dart';
import 'package:merlmovie_client/src/providers/player_state.dart';
import 'package:merlmovie_client/src/widgets/player_bottom_controls.dart';
import 'package:merlmovie_client/src/widgets/player_display_caption.dart';
import 'package:merlmovie_client/src/widgets/player_loading.dart';
import 'package:merlmovie_client/src/widgets/player_middle_controls.dart';
import 'package:merlmovie_client/src/widgets/player_select_episode.dart';
import 'package:merlmovie_client/src/widgets/player_subtitle_theme_editor.dart';
import 'package:merlmovie_client/src/widgets/player_top_controls.dart';
import 'package:merlmovie_client/src/widgets/player_video_builder.dart';
import 'package:merlmovie_client/src/widgets/prompt_dialog.dart';
import 'package:merlmovie_client/src/widgets/player_select_plugin.dart';
import 'package:merlmovie_client/src/widgets/webview_player.dart';
import 'package:provider/provider.dart';
import 'package:subtitle/subtitle.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MerlMovieClientPlayer extends StatefulWidget {
  final EmbedModel embed;
  final MerlMovieClientPlayerCallback? callback;
  final List<DeviceOrientation>? onDisposedDeviceOrientations;
  final List<PluginModel> plugins;
  final Duration initialPosition;
  final List<Season> seasons;
  final List<MovieModel> similar;
  final String? selectPluginSheetLabel;
  final AutoAdmobConfig? adConfig;
  final Future<DetailModel> Function(MovieModel movie)? onRequestDetail;
  final Future<DirectLink> Function(DirectLink link, EmbedModel embed)?
  onDirectLinkRequested;
  const MerlMovieClientPlayer({
    super.key,
    required this.embed,
    this.callback,
    this.onDisposedDeviceOrientations,
    this.plugins = const [],
    this.seasons = const [],
    this.similar = const [],
    this.selectPluginSheetLabel,
    this.initialPosition = Duration.zero,
    this.adConfig,
    this.onRequestDetail,
    this.onDirectLinkRequested,
  });

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

class _MerlMovieClientPlayerState extends State<MerlMovieClientPlayer>
    with TickerProviderStateMixin {
  AutoAdmob? autoAdmob;

  late EmbedModel embed;
  List<Season> seasons_arr = [];
  List<MovieModel> similar_arr = [];

  Duration position = Duration.zero;

  bool restoreSystemChrome = true;

  double progress = 0;

  bool isEditingSubtitleTheme = false;

  ValueNotifier<SubtitleTheme> subtitleTheme = ValueNotifier(
    SubtitleTheme.fromMap({}),
  );

  ValueNotifier<bool> hideControls = ValueNotifier<bool>(false);
  ValueNotifier<bool> isInitializing = ValueNotifier<bool>(true);

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

  AnimationController? _animationController;

  MovieModel? currentSimilar;

  void update() => mounted ? setState(() {}) : () {};

  Future initialize() async {
    if (widget.plugins.isEmpty) {
      await load_plugin(embed.plugin);
    } else {
      int length = widget.plugins.length;
      for (int i = 0; i < length; i++) {
        bool isLast = i + 1 >= length;
        bool isLoaded = await load_plugin(
          widget.plugins[i],
          showErrorOnRequest: isLast,
          showErrorOnLoadLink: isLast,
        );
        if (isLoaded) break;
      }
    }
  }

  Future<bool> load_plugin(
    PluginModel plugin, {
    bool showErrorOnRequest = true,
    bool? showErrorOnLoadLink,
  }) async {
    embed.plugin = plugin;
    if (plugin.useWebView) {
      restoreSystemChrome = false;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(primary: Colors.red),
              ),
              child: MerlMovieClientWebViewPlayer(
                embed: embed,
                onDisposedDeviceOrientations:
                    widget.onDisposedDeviceOrientations,
                adConfig: widget.adConfig,
              ),
            );
          },
        ),
      );
      return true;
    } else {
      await MerlMovieClient.closeWSSConnection();
      directLink = null;
      await controller?.dispose();
      controller = null;
      directLink = null;
      progress = 0;
      update();
      directLink = await MerlMovieClient.request(
        embed,
        onProgress: onRequestProgress,
        onError: showErrorOnRequest ? onRequestError : null,
      );
      update();
      if (directLink != null) {
        if (widget.onDirectLinkRequested != null) {
          directLink = await widget.onDirectLinkRequested!(directLink!, embed);
          update();
        }
        return await try_load_quality(
          directLink!.qualities,
          showErrorOnLoadLink,
        );
      } else {
        return false;
      }
    }
  }

  Future<bool> try_load_quality(
    List<QualityItem> qualities, [
    bool? showError,
  ]) async {
    if (mounted) {
      for (int i = 0; i < qualities.length; i++) {
        final qua = qualities[i];
        bool isLast = (i + 1) >= qualities.length;
        bool isLoaded = await changeQuality(
          qua,
          showError == true ? isLast : false,
        );
        if (isLoaded) {
          return true;
        }
      }
    }
    return false;
  }

  Future<bool> changeQuality(
    QualityItem quality, [
    bool showError = false,
  ]) async {
    if (currentQuality?.link != quality.link) {
      try {
        isInitializing.value = true;
        await controller?.dispose();
        controller = null;
        currentQuality = quality;
        controller = await create_video_controller(quality);
        update();
        hideControls.value = false;
        await controller?.initialize();
        controller?.addListener(playerListener);
        await controller?.seekTo(position);
        controller?.play().then((value) {
          hideControls.value = true;
          isInitializing.value = false;
          createAutoAd();
        });
        update();
        return true;
      } catch (err) {
        log(err.toString());
        log(
          "[${runtimeType.toString()}] Error loading source: ${quality.toMap()}",
        );
        if (showError) {
          onLoadError("Player error", "${err.toString()}\n");
        }
        hideControls.value = false;
        return false;
      }
    } else {
      return true;
    }
  }

  Future force_start_proxy() async {
    while (true) {
      if (!await MerlMovieHttpProxyService.isServing) {
        await MerlMovieHttpProxyService.background_serve();
        await Future.delayed(const Duration(seconds: 1));
      } else {
        break;
      }
    }
  }

  Future create_video_controller(QualityItem quality) async {
    if (quality.use_proxy) {
      await force_start_proxy();
      log(
        "\n[${runtimeType.toString()}] Create VideoPlayerController with proxy.\n",
      );
      return VideoPlayerController.networkUrl(
        Uri.parse(
          MerlMovieHttpProxyService.create_proxy_url(
            quality.link,
            quality.headers,
          ),
        ),
      );
    } else {
      return VideoPlayerController.networkUrl(
        Uri.parse(quality.link),
        httpHeaders: quality.headers ?? {},
      );
    }
  }

  void createAutoAd() {
    if (widget.adConfig != null && autoAdmob == null) {
      autoAdmob = AutoAdmob();
      autoAdmob?.initialize(config: widget.adConfig);
      autoAdmob?.onInterstitialAdReady = onAdReady;
    }
  }

  void onAdReady() async {
    log("[${runtimeType.toString()}] Ad is ready!");
    bool isPlaying = controller?.value.isPlaying == true;
    await controller?.pause();
    await autoAdmob?.showInterstitialAd();
    if (isPlaying) controller?.play();
  }

  void playerListener() {
    if (controller != null) {
      widget.callback?.onPositionChanged?.call(
        embed,
        controller!.value.position,
        controller!.value.duration,
      );
      position = controller!.value.position;
      if (!controller!.value.isPlaying) {
        hideControls.value = false;
      }
    }
  }

  void onRequestProgress(double progress) {
    this.progress = progress;
    update();
  }

  TextStyle? get dialogButtonTextStyle =>
      context.theme.textTheme.titleMedium?.copyWith(color: Colors.white);

  Future onRequestError(int status, String message) async {
    hideControls.value = false;
    bool? accepted = await showPromptDialog(
      title: "Error code $status",
      subtitle:
          "$message${widget.plugins.isNotEmpty ? "\nWould you like to change the source?" : ""}",
      titleStyle: context.theme.textTheme.titleLarge?.copyWith(
        color: Colors.white,
      ),
      subtitleStyle: context.theme.textTheme.bodyMedium?.copyWith(
        color: Colors.white70,
      ),
      negativeButtonTextStyle: dialogButtonTextStyle?.copyWith(
        color: dialogButtonTextStyle?.color?.withOpacity(.8),
      ),
      positiveButtonTextStyle: dialogButtonTextStyle,
    );
    if (accepted) {
      if (mounted) {
        PluginModel? plugin = await MerlMovieClientPlayer.selectPlugin(
          context,
          widget.plugins,
          embed,
          label: widget.selectPluginSheetLabel,
        );
        if (plugin != null) {
          onLinkChanged(plugin);
        }
      }
    }
  }

  Future onLoadError(String title, String message) async {
    bool? accepted = await showPromptDialog(
      title: title,
      subtitle:
          "$message${widget.plugins.isNotEmpty ? "\nWould you like to change the source?" : ""}",
      scrollableSubtitle: true,
      titleStyle: context.theme.textTheme.titleLarge?.copyWith(
        color: Colors.white,
      ),
      subtitleStyle: context.theme.textTheme.bodyMedium?.copyWith(
        color: Colors.white70,
      ),
      negativeButtonTextStyle: dialogButtonTextStyle?.copyWith(
        color: dialogButtonTextStyle?.color?.withOpacity(.8),
      ),
      positiveButtonTextStyle: dialogButtonTextStyle,
    );
    if (accepted) {
      if (mounted) {
        PluginModel? plugin = await MerlMovieClientPlayer.selectPlugin(
          context,
          widget.plugins,
          embed,
          label: widget.selectPluginSheetLabel,
        );
        if (plugin != null) {
          onLinkChanged(plugin);
        }
      }
    }
  }

  void onLinkChanged(PluginModel plugin) async {
    embed.plugin = plugin;
    update();
    if (embed.plugin.useWebView) {
      restoreSystemChrome = false;
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) {
              return Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(primary: Colors.red),
                ),
                child: MerlMovieClientWebViewPlayer(
                  embed: embed,
                  onDisposedDeviceOrientations:
                      widget.onDisposedDeviceOrientations,
                  adConfig: widget.adConfig,
                ),
              );
            },
          ),
        );
      }
    } else {
      load_plugin(plugin, showErrorOnRequest: true, showErrorOnLoadLink: true);
    }
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
      embed,
      label: widget.selectPluginSheetLabel,
    );
    if (plugin != null) {
      onLinkChanged(plugin);
    }
  }

  Future onEpisodeChanged(Episode episode) async {
    if (episode.seasonNumber != int.parse(embed.season) ||
        episode.episodeNumber != int.parse(embed.episode)) {
      embed.season = episode.seasonNumber.toString();
      embed.episode = episode.episodeNumber.toString();
      embed.thumbnail = TheMovieDbApi.getImage(
        episode.stillPath,
        TMDBImageSize.original,
      );
      position = Duration.zero;
      subtitle?.children = [];
      subtitle?.real_link = null;
      subtitles.value = [];
      update();
      initialize();
    }
  }

  void onEditSubtitleThemeClicked() {
    hideControls.value = true;
    setState(() {
      isEditingSubtitleTheme = true;
    });
  }

  Future onSubtitleChanged(SubtitleItem? subtitle) async {
    this.subtitle = subtitle;
    update();
    if (subtitle == null) {
      subtitles.value = [];
    } else {
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

  Future onSimilarChanged(MovieModel movie) async {
    assert(TheMovieDbApi.api_keys.isNotEmpty, "The TMDb Api keys must be set.");
    if (widget.onRequestDetail != null) {
      directLink = null;
      progress = 0;
      currentSimilar = movie;
      isInitializing.value = true;
      subtitles.value = [];
      subtitle = null;
      currentQuality = null;
      embed.thumbnail = TheMovieDbApi.getImage(
        movie.backdropPath,
        TMDBImageSize.original,
      );
      embed.title_logo = TheMovieDbApi.getTitleLogo(
        movie.type,
        movie.id.toString(),
        TMDBImageSize.w300,
      );
      update();
      await force_start_proxy();
      await MerlMovieClient.closeWSSConnection();
      await controller?.dispose();
      controller = null;
      position = Duration.zero;
      update();
      bool isLastSimilar = similar_arr.last.unique == movie.unique;
      final detail = await widget.onRequestDetail!(movie);
      embed.detail = detail;
      embed.type = detail.type;
      embed.tmdbId = movie.id.toString();
      embed.title = movie.real_title;
      embed.imdbId = detail.externalIds.imdbId;
      seasons_arr = detail.seasons;
      if (isLastSimilar) {
        similar_arr = [
          ...detail.recommendations.results,
          ...detail.similar.results,
        ];
      }
      update();
      if (detail.type == "tv" && detail.seasons.isNotEmpty) {
        Episode? episode = await showModalBottomSheet(
          context: NavigatorKey.currentContext!,
          isScrollControlled: true,
          builder: (context) {
            return PlayerSelectEpisodeSheet(
              seasons: detail.seasons,
              currentEpisode: null,
            );
          },
        );
        if (episode != null) {
          embed.season = episode.seasonNumber.toString();
          embed.episode = episode.episodeNumber.toString();
          embed.thumbnail = TheMovieDbApi.getImage(
            episode.stillPath,
            TMDBImageSize.original,
          );
        } else {
          embed.season =
              detail.seasons.first.episodes.first.seasonNumber.toString();
          embed.episode =
              detail.seasons.first.episodes.first.episodeNumber.toString();
          embed.thumbnail = TheMovieDbApi.getImage(
            detail.seasons.first.episodes.first.stillPath,
            TMDBImageSize.original,
          );
        }
      }
    }
    update();
    initialize();
  }

  void showHideControls() {
    if (controller?.value.isPlaying != true || isEditingSubtitleTheme) return;
    hideControls.value = !hideControls.value;
    preventHideControls();
  }

  void preventHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      hideControls.value = controller?.value.isPlaying == true;
    });
  }

  Future<bool> askToExit() async {
    bool accepted = await showPromptDialog(
      title: "Are you want to exit this page?",
      titleStyle: context.theme.textTheme.titleLarge?.copyWith(
        color: Colors.white,
      ),
      subtitleStyle: context.theme.textTheme.bodyMedium?.copyWith(
        color: Colors.white70,
      ),
      negativeButtonTextStyle: dialogButtonTextStyle?.copyWith(
        color: dialogButtonTextStyle?.color?.withOpacity(.8),
      ),
      positiveButtonTextStyle: dialogButtonTextStyle,
    );
    return accepted;
  }

  void hideControlsListener() {
    if (!hideControls.value) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top],
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }
  }

  @override
  void initState() {
    position = widget.initialPosition;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    embed = EmbedModel.fromMap(widget.embed.toMap());
    seasons_arr = [...widget.seasons];
    similar_arr = [...widget.similar];
    hideControls.addListener(hideControlsListener);
    SubtitleTheme.getTheme().then((value) => subtitleTheme.value = value);
    MerlMovieClientPlayer.setDeviceOrientationAndSystemUI();
    WakelockPlus.enable();
    initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlayerStateProvider>(context, listen: false).setValue(true);
    });
    super.initState();
  }

  @override
  void dispose() {
    if (restoreSystemChrome) {
      MerlMovieClientPlayer.restoreDeviceOrientationAndSystemUI(
        widget.onDisposedDeviceOrientations,
      );
    }
    WakelockPlus.disable();
    MerlMovieClient.closeWSSConnection();
    autoAdmob?.destroy();
    autoAdmob = null;
    _animationController?.dispose();
    hideControls.removeListener(hideControlsListener);
    if (controller != null) {
      if (controller!.value.position.inMinutes >=
          (controller!.value.duration.inMinutes - 10)) {
        widget.callback?.onDecideAsWatched?.call(embed);
      }
    }
    controller?.dispose();
    controller = null;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (NavigatorKey.currentContext != null) {
        Provider.of<PlayerStateProvider>(
          NavigatorKey.currentContext!,
          listen: false,
        ).setValue(false);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => askToExit(),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          toolbarHeight: 0,
          leadingWidth: 0,
          leading: SizedBox(),
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent,
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
              if (controller != null)
                PlayerVideoBuilder(
                  controller: controller,
                  viewType: videoViewType,
                ),
              if (controller != null && !isEditingSubtitleTheme)
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
              if (isEditingSubtitleTheme)
                Positioned(
                  child: ValueListenableBuilder(
                    valueListenable: subtitleTheme,
                    builder: (context, currentSubtitleTheme, _) {
                      return PlayerSubtitleThemeEditor(
                        current: currentSubtitleTheme,
                        onClose:
                            () =>
                                setState(() => isEditingSubtitleTheme = false),
                        onChanged: (theme) {
                          subtitleTheme.value = theme;
                          SubtitleTheme.setTheme(theme);
                        },
                      );
                    },
                  ),
                ),
              if (!isEditingSubtitleTheme)
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
                                        embed: embed,
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
                                        preventHideControls:
                                            preventHideControls,
                                      ),
                                      Center(
                                        child: PlayerMiddleControls(
                                          controller: controller,
                                          isInitializing: isInitializing,
                                          animationController:
                                              _animationController,
                                          preventHideControls:
                                              preventHideControls,
                                        ),
                                      ),
                                      PlayerBottomControls(
                                        controller: controller,
                                        currentViewType: videoViewType,
                                        currentPlaybackSpeed: playbackSpeed,
                                        currentQuality: currentQuality,
                                        currentEpisode: seasons_arr
                                            .findCurrentEpisode(embed),
                                        qualities: directLink?.qualities ?? [],
                                        seasons: seasons_arr,
                                        similar: similar_arr,
                                        currentSubtitle: subtitle,
                                        currentSimilar: currentSimilar,
                                        subtitles: directLink?.subtitles ?? [],
                                        onViewTypeChanged: onViewTypeChanged,
                                        onQualityChanged: onQualityChanged,
                                        onEpisodeChanged: onEpisodeChanged,
                                        onSubtitleChanged: onSubtitleChanged,
                                        preventHideControls:
                                            preventHideControls,
                                        onSimilarChanged: onSimilarChanged,
                                        onPlaybackSpeedChanged:
                                            onPlaybackSpeedChanged,
                                        onEditSubtitleThemeClicked:
                                            onEditSubtitleThemeClicked,
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
                    embed: embed,
                    progress: progress,
                    plugins: widget.plugins,
                    currentSimilar: currentSimilar,
                    seasons: seasons_arr,
                    similar: similar_arr,
                    currentEpisode: seasons_arr.findCurrentEpisode(embed),
                    sheetLabel: widget.selectPluginSheetLabel,
                    onPluginChanged: onLinkChanged,
                    onSimilarChanged: onSimilarChanged,
                    onEpisodeChanged: onEpisodeChanged,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
