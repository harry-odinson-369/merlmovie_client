import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/helpers/generate.dart';
import 'package:merlmovie_client/src/providers/player_state.dart';
import 'package:merlmovie_client/src/widgets/webview_url_player_url_selector.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebViewURLPlayerWidget extends StatefulWidget {
  final List<URLPlayerModel> urls;
  final List<DeviceOrientation>? onDisposedDeviceOrientations;
  const WebViewURLPlayerWidget({
    super.key,
    required this.urls,
    this.onDisposedDeviceOrientations,
  });

  @override
  State<WebViewURLPlayerWidget> createState() => _WebViewURLPlayerWidgetState();
}

class _WebViewURLPlayerWidgetState extends State<WebViewURLPlayerWidget> {
  bool isLoading = true;

  URLPlayerModel current = URLPlayerModel.fromMap({});
  late WebViewController controller;

  GAdController? gAdController;

  Timer? _scriptExecuteTimer;
  Timer? _progressTimer;
  Timer? _actionButtonTimer;
  Timer? _bgUrlTimer;

  ValueNotifier<String?> bgUrlNotifier = ValueNotifier(null);
  ValueNotifier<bool> actionButtonNotifier = ValueNotifier(true);
  ValueNotifier<int> progressNotifier = ValueNotifier(0);

  WebViewController createWebView() {
    if (Platform.isIOS) {
      WebKitWebViewController wk = WebKitWebViewController(
        WebKitWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
          const PlatformWebViewControllerCreationParams(),
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        ),
      );
      controller = WebViewController.fromPlatform(wk);
    } else {
      AndroidWebViewController wk = AndroidWebViewController(
        AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
          PlatformWebViewControllerCreationParams(),
        ),
      );
      wk.setCustomWidgetCallbacks(
        onShowCustomWidget: onShowCustomWidget,
        onHideCustomWidget: () {
          Navigator.of(NavigatorKey.currentContext!).pop();
        },
      );
      wk.setMediaPlaybackRequiresUserGesture(false);
      controller = WebViewController.fromPlatform(wk);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setNavigationDelegate(navigationDelegate());
    controller.setBackgroundColor(Colors.black);
    return controller;
  }

  void loadUrl(URLPlayerModel url) {
    if (url.url == current.url) return;
    current = url;
    controller.loadRequest(Uri.parse(url.url), headers: url.headers);
    update();
  }

  void onShowCustomWidget(Widget widget, void Function() onCustomWidgetHidden) {
    Navigator.of(NavigatorKey.currentContext!).push(
      MaterialPageRoute(
        builder: (context) {
          return Stack(
            children: [
              Positioned(
                bottom: -1,
                top: -1,
                left: -1,
                right: -1,
                child: SizedBox(
                  height: context.screen.height,
                  width: context.screen.width,
                  child: widget,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  NavigationDelegate navigationDelegate() {
    return NavigationDelegate(
      onPageFinished: (url) => onProgress(100),
      onProgress: (pro) => onProgress(pro),
      onNavigationRequest: (request) async {
        final uri = Uri.parse(request.url);
        if (uri.host == Uri.parse(current.url).host) {
          return NavigationDecision.navigate;
        }
        bool isMatched = current.allowed_hosts.exist((e) => e == uri.host);
        if (request.isMainFrame && !isMatched) {
          bgUrlNotifier.value = request.url;
          if (BlockedURLsCallback != null) {
            var currentUrl = await controller.currentUrl();
            if (currentUrl != null && currentUrl.startsWith("http")) {
              final uri = Uri.parse(currentUrl);
              BlockedURLsCallback!(request.url, uri.origin);
            }
          }
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    );
  }

  void onProgress(int value) {
    progressNotifier.value = value;
    if (value >= 100) {
      _scriptExecuteTimer?.cancel();
      _scriptExecuteTimer = null;
      _scriptExecuteTimer ??= Timer(
        Duration(milliseconds: current.executeScriptMs),
        () async {
          String script = current.script ?? "";
          if (script.isNotEmpty) {
            if (script.startsWith("http")) {
              final newScript = await ScriptHelper.getScriptFromUrl(script);
              if (newScript != null) script = newScript;
            }
            controller.runJavaScript(script);
          }
        },
      );
      _progressTimer?.cancel();
      _progressTimer = null;
      _progressTimer ??= Timer(const Duration(seconds: 1), () {
        isLoading = false;
        update();
        if (gAdController == null) {
          gAdController = GAdController();
          gAdController?.onShowed = pauseEveryVideos;
          gAdController?.onClosed = playEveryVideos;
          gAdController?.create();
        }
        Future.delayed(const Duration(seconds: 3), () {
          actionButtonNotifier.value = false;
        });
      });
    }
  }

  void pauseEveryVideos() {
    controller.runJavaScript(
      "document.querySelectorAll('video').forEach(v => v.pause());",
    );
  }

  void playEveryVideos() {
    controller.runJavaScript(
      "document.querySelectorAll('video').forEach(v => v.play());",
    );
  }

  TextStyle? get dialogButtonTextStyle =>
      context.theme.textTheme.titleMedium?.copyWith(color: Colors.white);

  Future<bool> askToExit() async {
    bool accepted = await showPromptDialog(
      title: "Are you want to exit this page?",
      backgroundColor: Colors.grey.shade800,
      cupertinoBrightness: Brightness.dark,
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
    toggleShowHideBarButtons(true);
    bool isYes = await askToExit();
    if (isYes) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void toggleShowHideBarButtons([bool? value]) {
    actionButtonNotifier.value = value ?? !actionButtonNotifier.value;
    _actionButtonTimer?.cancel();
    _actionButtonTimer = null;
    if (actionButtonNotifier.value) {
      _actionButtonTimer ??= Timer(Duration(seconds: 3), () {
        actionButtonNotifier.value = false;
      });
    }
  }

  void onBgUrlLoadStop() {
    _bgUrlTimer?.cancel();
    _bgUrlTimer = null;
    final dur = Duration(seconds: GenerateHelper.random(6, 30));
    debugPrint("Background url will close in the next ${dur.inSeconds} seconds.");
    _bgUrlTimer ??= Timer(dur, () => bgUrlNotifier.value = null);
  }

  void showURLsSelector() async {
    URLPlayerModel? url = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return WebViewURLsPlayerURLSelector(
          urls: widget.urls,
          current: current,
        );
      },
    );
    if (url != null && url.url != current.url) {
      loadUrl(url);
    }
  }

  void update() => mounted ? setState(() {}) : () {};

  @override
  void initState() {
    MerlMovieClientPlayer.setDeviceOrientationAndSystemUI();
    WakelockPlus.enable().catchError((er) {});
    createWebView();
    loadUrl(widget.urls.first);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      use<PlayerStateProvider>().setValue(true);
    });
    super.initState();
  }

  @override
  void dispose() {
    MerlMovieClientPlayer.restoreDeviceOrientationAndSystemUI(
      widget.onDisposedDeviceOrientations,
    );
    WakelockPlus.disable().catchError((er) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      use<PlayerStateProvider>().setValue(false);
    });
    gAdController?.dispose();
    gAdController = null;
    _scriptExecuteTimer?.cancel();
    _scriptExecuteTimer = null;
    _actionButtonTimer?.cancel();
    _actionButtonTimer = null;
    _bgUrlTimer?.cancel();
    _bgUrlTimer = null;
    controller.setNavigationDelegate(NavigationDelegate()).catchError((er) {});
    controller.loadRequest(Uri.parse("about:blank")).catchError((er) {});
    bgUrlNotifier.value = null;
    _progressTimer?.cancel();
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
            Positioned(
              top: -1,
              bottom: -1,
              left: -1,
              right: -1,
              child: SizedBox(
                height: context.screen.height,
                width: context.screen.width,
                child: WebViewWidget(controller: controller),
              ),
            ),
            Positioned(
              left: -1,
              right: -1,
              top: -context.screen.height * 1.2,
              child: ValueListenableBuilder(
                valueListenable: bgUrlNotifier,
                builder: (context, bgUrl, child) {
                  if (bgUrl == null) return SizedBox();
                  return SizedBox(
                    height: context.screen.height,
                    width: context.screen.width,
                    child: MerlMovieClientWebViewWidget(
                      link: bgUrl,
                      onPageFinished: (url) => onBgUrlLoadStop(),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder(
                valueListenable: progressNotifier,
                builder: (context, percent, child) {
                  if (percent >= 99 || percent <= 0) return SizedBox();
                  return LinearProgressIndicator(value: percent / 100);
                },
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: ValueListenableBuilder(
                valueListenable: actionButtonNotifier,
                builder: (context, isShowButton, _) {
                  final buttons = [
                    if (widget.urls.length > 1)
                      Container(
                        margin: EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        height: 32,
                        width: 32,
                        child: InkWell(
                          onTap: showURLsSelector,
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
                            (isShowButton ? 48 * buttons.length : 0).toDouble(),
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
                            isShowButton
                                ? CupertinoIcons.forward
                                : CupertinoIcons.back,
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
