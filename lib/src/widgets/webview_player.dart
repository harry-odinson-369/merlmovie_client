// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/extensions/seasons.dart';
import 'package:merlmovie_client/src/helpers/themoviedb.dart';
import 'package:merlmovie_client/src/providers/player_state.dart';
import 'package:merlmovie_client/src/widgets/player_loading.dart';
import 'package:merlmovie_client/src/widgets/player_select_episode.dart';
import 'package:merlmovie_client/src/widgets/player_select_similar_sheet.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class MerlMovieClientWebViewPlayer extends StatefulWidget {
  final EmbedModel embed;
  final List<PluginModel> plugins;
  final String? selectPluginSheetLabel;
  final List<DeviceOrientation>? onDisposedDeviceOrientations;
  final Future<DetailModel> Function(MovieModel movie)? onRequestDetail;
  final MerlMovieClientPlayerCallback? callback;
  final Future<DirectLink> Function(DirectLink link, EmbedModel embed)?
  onDirectLinkRequested;
  final List<MovieModel> similar;
  const MerlMovieClientWebViewPlayer({
    super.key,
    required this.embed,
    this.onDisposedDeviceOrientations,
    this.plugins = const [],
    this.similar = const [],
    this.selectPluginSheetLabel,
    this.onRequestDetail,
    this.callback,
    this.onDirectLinkRequested,
  });

  @override
  State<MerlMovieClientWebViewPlayer> createState() =>
      _MerlMovieClientWebViewPlayerState();
}

class _MerlMovieClientWebViewPlayerState
    extends State<MerlMovieClientWebViewPlayer> {
  double webProgress = 0;

  bool isLoading = true;

  bool restoreSystemChrome = true;

  ValueNotifier<bool> hideBarButton = ValueNotifier(false);

  List<MerlMovieClientWebViewWidget> popup_links = [];

  WebViewController? webViewFlutterController;

  Timer? _webProgressTimer;

  Timer? _hideBarButtonsTimer;

  FlutterAutoAdmob? _flutterAutoAdmob;

  Future createWebViewFlutterController() async {
    if (Platform.isIOS) {
      WebKitWebViewController wk = WebKitWebViewController(
        WebKitWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
          const PlatformWebViewControllerCreationParams(),
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        ),
      );
      webViewFlutterController = WebViewController.fromPlatform(wk);
    } else {
      AndroidWebViewController wk = AndroidWebViewController(
        AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
          PlatformWebViewControllerCreationParams(),
        ),
      );
      wk.setMediaPlaybackRequiresUserGesture(false);
      webViewFlutterController = WebViewController.fromPlatform(wk);
      (webViewFlutterController!.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    webViewFlutterController?.setJavaScriptMode(JavaScriptMode.unrestricted);
    webViewFlutterController?.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) => onWebRequestProgress(100),
        onProgress: (pro) => onWebRequestProgress(pro.toDouble()),
        onNavigationRequest: (request) async {
          final uri = Uri.parse(request.url);
          bool isMatched = widget.embed.plugin.allowedDomains.exist(
            (e) => e == uri.domainNameOnly,
          );
          if (request.isMainFrame && !isMatched) {
            if (popup_links.length >= 3) {
              popup_links.clear();
            }
            popup_links.add(MerlMovieClientWebViewWidget(link: request.url));
            update();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
    webViewFlutterController?.loadRequest(Uri.parse(widget.embed.request_url));
    update();
  }

  void update() => mounted ? setState(() {}) : () {};

  void onWebRequestProgress(double prog) {
    webProgress = prog;
    update();
    if (prog >= 100) {
      _webProgressTimer?.cancel();
      _webProgressTimer = null;
      _webProgressTimer ??= Timer(const Duration(seconds: 1), () {
        isLoading = false;
        update();
        createAutoAd();
        Future.delayed(const Duration(seconds: 1), () {
          if (widget.embed.plugin.script.isNotEmpty) {
            webViewFlutterController?.runJavaScript(widget.embed.plugin.script);
          }
        });
        Future.delayed(const Duration(seconds: 3), () {
          hideBarButton.value = true;
        });
      });
    }
  }

  void createAutoAd() {
    if (MerlMovieClient.adConfig != null) {
      _flutterAutoAdmob = FlutterAutoAdmob();
      _flutterAutoAdmob?.configure(config: MerlMovieClient.adConfig!);
      _flutterAutoAdmob?.interstitial.onLoadedCallback = () {
        _flutterAutoAdmob?.interstitial.show();
      };
    } else {
      FlutterAutoAdmob.ads.interstitial.onLoadedCallback = () {
        FlutterAutoAdmob.ads.interstitial.show();
      };
    }
  }

  TextStyle? get dialogButtonTextStyle =>
      context.theme.textTheme.titleMedium?.copyWith(color: Colors.white);

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

  Future exitIfYes() async {
    toggleShowHideBarButtons(false);
    bool isYes = await askToExit();
    if (isYes) {
      if (mounted) Navigator.of(context).pop();
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

  void playNewEmbed(EmbedModel newEmbed, [List<MovieModel>? similar_arr]) {
    restoreSystemChrome = false;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      MerlMovieClient.open(
        newEmbed,
        pushReplacement: true,
        plugins: widget.plugins,
        callback: widget.callback,
        onRequestDetail: widget.onRequestDetail,
        onDirectLinkRequested: widget.onDirectLinkRequested,
        selectPluginSheetLabel: widget.selectPluginSheetLabel,
        onDisposedDeviceOrientations: widget.onDisposedDeviceOrientations,
      );
    });
  }

  void onPluginChanged(PluginModel plugin) {
    EmbedModel newEmbed = MerlMovieClient.create_embed(
      plugin,
      widget.embed.detail,
      widget.embed.detail.seasons.findCurrentEpisode(widget.embed),
    );
    playNewEmbed(newEmbed);
  }

  void onEpisodeChanged(Episode episode) {
    EmbedModel newEmbed = MerlMovieClient.create_embed(
      widget.embed.plugin,
      widget.embed.detail,
      episode,
    );
    playNewEmbed(newEmbed);
  }

  void onSimilarChanged(MovieModel movie) async {
    assert(TheMovieDbApi.api_keys.isNotEmpty, "The TMDb Api keys must be set.");
    if (widget.onRequestDetail != null) {
      await force_start_proxy();
      widget.embed.thumbnail = TheMovieDbApi.getImage(
        movie.backdropPath,
        TMDBImageSize.original,
      );
      widget.embed.title_logo = TheMovieDbApi.getTitleLogo(
        movie.type,
        movie.id.toString(),
        TMDBImageSize.w300,
      );
      isLoading = true;
      webProgress = 20;
      update();
      final detail = await widget.onRequestDetail!(movie);
      webProgress = 50;
      update();
      Episode? episode;
      if (detail.type == "tv" && detail.seasons.isNotEmpty) {
        episode = await showModalBottomSheet(
          context: NavigatorKey.currentContext!,
          isScrollControlled: true,
          builder: (context) {
            return PlayerSelectEpisodeSheet(
              seasons: detail.seasons,
              currentEpisode: null,
            );
          },
        );
        episode ??= detail.seasons.first.episodes.first;
      }
      EmbedModel newEmbed = MerlMovieClient.create_embed(
        widget.embed.plugin,
        detail,
        episode,
      );
      bool isLastSimilar = widget.similar.last.unique == movie.unique;
      var similar_arr =
          isLastSimilar
              ? [...detail.recommendations.results, ...detail.similar.results]
              : widget.similar;
      playNewEmbed(newEmbed, similar_arr);
    }
  }

  void changePlugin() async {
    toggleShowHideBarButtons(false);
    PluginModel? plugin = await MerlMovieClientPlayer.selectPlugin(
      context,
      widget.plugins,
      widget.embed,
      label: widget.selectPluginSheetLabel,
    );
    if (plugin != null && plugin != widget.embed.plugin) {
      isLoading = true;
      webProgress = 20;
      update();
      await Future.delayed(Duration(milliseconds: 300));
      onPluginChanged(plugin);
    }
  }

  void changeEpisode() async {
    toggleShowHideBarButtons(false);
    Episode? episode = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return PlayerSelectEpisodeSheet(
          seasons: widget.embed.detail.seasons,
          currentEpisode: widget.embed.detail.seasons.findCurrentEpisode(
            widget.embed,
          ),
        );
      },
    );
    if (episode != null) {
      if (episode.seasonNumber != int.parse(widget.embed.season) ||
          episode.episodeNumber != int.parse(widget.embed.episode)) {
        isLoading = true;
        webProgress = 20;
        update();
        await Future.delayed(Duration(milliseconds: 300));
        onEpisodeChanged(episode);
      }
    }
  }

  void changeSimilar() async {
    toggleShowHideBarButtons(false);
    var current = MovieModel.fromJson(widget.embed.detail.toJson());
    MovieModel? selected = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return PlayerSelectSimilarSheet(
          similar: widget.similar,
          current: current,
        );
      },
    );
    if (selected != null) {
      if (selected.unique != current.unique) {
        onSimilarChanged(selected);
      } else {
        changeEpisode();
      }
    }
  }

  void toggleShowHideBarButtons([bool? value]) {
    hideBarButton.value = value ?? !hideBarButton.value;
    _hideBarButtonsTimer?.cancel();
    _hideBarButtonsTimer = null;
    if (!hideBarButton.value) {
      _hideBarButtonsTimer ??= Timer(Duration(seconds: 3), () {
        hideBarButton.value = true;
      });
    }
  }

  @override
  void initState() {
    MerlMovieClientPlayer.setDeviceOrientationAndSystemUI();
    WakelockPlus.enable();
    createWebViewFlutterController();
    update();
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
      WakelockPlus.disable();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (NavigatorKey.currentContext != null) {
          Provider.of<PlayerStateProvider>(
            NavigatorKey.currentContext!,
            listen: false,
          ).setValue(false);
        }
      });
    }
    FlutterAutoAdmob.ads.interstitial.onLoadedCallback = null;
    webViewFlutterController?.setNavigationDelegate(NavigationDelegate());
    webViewFlutterController?.loadRequest(Uri.parse("about:blank"));
    webViewFlutterController = null;
    popup_links.clear();
    _webProgressTimer?.cancel();
    _hideBarButtonsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await askToExit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        body: Stack(
          children: [
            if (!isLoading)
              IndexedStack(
                index: 0,
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: context.screen.height,
                    width: context.screen.width,
                    child: WebViewWidget(controller: webViewFlutterController!),
                  ),
                  ...popup_links.limit(3),
                ],
              ),
            if (isLoading)
              PlayerLoading(
                progress: webProgress,
                embed: widget.embed,
                plugins: widget.plugins,
                similar: widget.similar,
                seasons: widget.embed.detail.seasons,
                selectPluginSheetLabel: widget.selectPluginSheetLabel,
                currentSimilar: widget.similar.firstWhereOrNull(
                  (e) => e.unique == widget.embed.detail.unique,
                ),
                currentEpisode: widget.embed.detail.seasons.findCurrentEpisode(
                  widget.embed,
                ),
                onEpisodeChanged: onEpisodeChanged,
                onPluginChanged: onPluginChanged,
                onSimilarChanged: onSimilarChanged,
              ),
            if (!isLoading)
              Positioned(
                right: 16,
                top: 16,
                child: ValueListenableBuilder(
                  valueListenable: hideBarButton,
                  builder: (context, isHideBarButton, _) {
                    final buttons = [
                      if (widget.similar.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          height: 32,
                          width: 32,
                          child: InkWell(
                            onTap: changeSimilar,
                            child: Icon(
                              CupertinoIcons.list_bullet_below_rectangle,
                              color: Colors.white.withOpacity(.8),
                              size: 20,
                            ),
                          ),
                        ),
                      if (widget.embed.detail.seasons.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          height: 32,
                          width: 32,
                          child: InkWell(
                            onTap: changeEpisode,
                            child: Icon(
                              CupertinoIcons.rectangle_stack,
                              color: Colors.white.withOpacity(.8),
                              size: 20,
                            ),
                          ),
                        ),
                      if (widget.plugins.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          height: 32,
                          width: 32,
                          child: InkWell(
                            onTap: changePlugin,
                            child: Icon(
                              Icons.format_list_bulleted,
                              color: Colors.white.withOpacity(.8),
                              size: 22,
                            ),
                          ),
                        ),
                      Container(
                        margin: EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        height: 32,
                        width: 32,
                        child: InkWell(
                          onTap: exitIfYes,
                          child: Icon(
                            Icons.close,
                            color: Colors.white.withOpacity(.8),
                            size: 24,
                          ),
                        ),
                      ),
                    ];
                    return Row(
                      children: [
                        AnimatedContainer(
                          width:
                              (isHideBarButton ? 0 : 48 * buttons.length)
                                  .toDouble(),
                          duration: Duration(milliseconds: 200),
                          child: SizedBox(
                            height: 32,
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              scrollDirection: Axis.horizontal,
                              children: buttons,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          height: 32,
                          width: 32,
                          child: InkWell(
                            onTap: toggleShowHideBarButtons,
                            child: Icon(
                              isHideBarButton
                                  ? CupertinoIcons.back
                                  : CupertinoIcons.forward,
                              color: Colors.white.withOpacity(.8),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
