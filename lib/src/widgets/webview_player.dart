// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/extensions/uri.dart';
import 'package:merlmovie_client/src/providers/player_state.dart';
import 'package:merlmovie_client/src/widgets/player_loading.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class MerlMovieClientWebViewPlayer extends StatefulWidget {
  final EmbedModel embed;
  final List<DeviceOrientation>? onDisposedDeviceOrientations;
  final AutoAdmobConfig? adConfig;
  const MerlMovieClientWebViewPlayer({
    super.key,
    required this.embed,
    this.onDisposedDeviceOrientations,
    this.adConfig,
  });

  @override
  State<MerlMovieClientWebViewPlayer> createState() =>
      _MerlMovieClientWebViewPlayerState();
}

class _MerlMovieClientWebViewPlayerState
    extends State<MerlMovieClientWebViewPlayer> {
  double webProgress = 0;

  bool isLoading = true;

  GlobalKey? webViewKey;

  List<MerlMovieClientWebViewWidget> popup_links = [];

  InAppWebViewSettings get settings => InAppWebViewSettings(
    allowsInlineMediaPlayback: true,
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
    supportMultipleWindows: true,
    mediaPlaybackRequiresUserGesture: false,
  );

  WebViewController? webViewFlutterController;

  Timer? _webProgressTimer;

  AutoAdmob? autoAdmob;

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
        onPageFinished: (url) {
          if (widget.embed.plugin.script.isNotEmpty) {
            webViewFlutterController?.runJavaScript(widget.embed.plugin.script);
          }
          onWebRequestProgress(100);
        },
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
    if (widget.embed.plugin.useIframe) {
      webViewFlutterController?.loadHtmlString(widget.embed.playableIframe);
    } else {
      webViewFlutterController?.loadRequest(Uri.parse(widget.embed.request_url));
    }
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
      });
    }
  }

  void createAutoAd() {
    if (widget.adConfig != null && autoAdmob == null) {
      autoAdmob = AutoAdmob();
      autoAdmob?.initialize(config: widget.adConfig);
      autoAdmob?.onInterstitialAdReady = () {
        autoAdmob?.showInterstitialAd();
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
    bool isYes = await showPromptDialog(
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
    if (isYes) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void onFlutterInAppWebViewLoadStop(
    InAppWebViewController controller,
    WebUri? uri,
  ) {
    if (widget.embed.plugin.script.isNotEmpty) {
      controller.evaluateJavascript(source: widget.embed.plugin.script);
    }
  }

  Future<NavigationActionPolicy> onFlutterInAppWebViewShouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final uri = Uri.parse(action.request.url.toString());
    bool isMatched = widget.embed.plugin.allowedDomains.exist(
      (e) => e == uri.domainNameOnly,
    );
    if (action.isForMainFrame && !isMatched) {
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  Future<bool> onCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction action,
  ) async {
    if (popup_links.length >= 3) {
      popup_links.clear();
    }
    if (action.request.url != null) {
      popup_links.add(
        MerlMovieClientWebViewWidget(link: action.request.url.toString()),
      );
      update();
    }

    return true;
  }

  @override
  void initState() {
    MerlMovieClientPlayer.setDeviceOrientationAndSystemUI();
    WakelockPlus.enable();
    if (widget.embed.plugin.webView == WebViewProviderType.webview_flutter) {
      createWebViewFlutterController();
    }
    webViewKey = GlobalKey();
    update();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlayerStateProvider>(context, listen: false).setValue(true);
    });
    super.initState();
  }

  @override
  void dispose() {
    MerlMovieClientPlayer.restoreDeviceOrientationAndSystemUI(
      widget.onDisposedDeviceOrientations,
    );
    WakelockPlus.disable();
    webViewFlutterController?.setNavigationDelegate(NavigationDelegate());
    webViewFlutterController?.loadRequest(Uri.parse("about:blank"));
    webViewFlutterController = null;
    webViewKey?.currentState?.dispose();
    webViewKey = null;
    autoAdmob?.destroy();
    autoAdmob = null;
    popup_links.clear();
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
      onWillPop: () async {
        return await askToExit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(
              index: 0,
              children: [
                if (widget.embed.plugin.webView ==
                        WebViewProviderType.webview_flutter &&
                    webViewFlutterController != null)
                  WebViewWidget(
                    key: webViewKey,
                    controller: webViewFlutterController!,
                  ),
                if (widget.embed.plugin.webView ==
                    WebViewProviderType.flutter_inappwebview)
                  InAppWebView(
                    key: webViewKey,
                    initialUrlRequest:
                        widget.embed.plugin.useIframe
                            ? null
                            : URLRequest(
                              url: WebUri(widget.embed.request_url),
                              headers: widget.embed.plugin.headers,
                            ),
                    initialData:
                        widget.embed.plugin.useIframe
                            ? InAppWebViewInitialData(
                              data: widget.embed.playableIframe,
                              baseUrl: WebUri(widget.embed.request_url),
                            )
                            : null,
                    initialSettings: settings,
                    onProgressChanged:
                        (controller, progress) =>
                            onWebRequestProgress(progress.toDouble()),
                    onCreateWindow: onCreateWindow,
                    onLoadStop: onFlutterInAppWebViewLoadStop,
                    shouldOverrideUrlLoading:
                        onFlutterInAppWebViewShouldOverrideUrlLoading,
                  ),
                ...popup_links.limit(3),
              ],
            ),
            if (isLoading)
              PlayerLoading(progress: webProgress, embed: widget.embed),
            if (!isLoading)
              Positioned(
                right: 16,
                top: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: InkWell(
                    onTap: exitIfYes,
                    child: Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
