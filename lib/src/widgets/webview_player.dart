import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/extensions/uri.dart';
import 'package:merlmovie_client/src/widgets/player_loading.dart';
import 'package:merlmovie_client/src/widgets/prompt_dialog.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class MerlMovieClientWebViewPlayer extends StatefulWidget {
  final EmbedModel embed;
  final List<DeviceOrientation>? onDisposedDeviceOrientations;
  const MerlMovieClientWebViewPlayer({
    super.key,
    required this.embed,
    this.onDisposedDeviceOrientations,
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

  InAppWebViewSettings get settings => InAppWebViewSettings(
    allowsInlineMediaPlayback: true,
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
    supportMultipleWindows: true,
    mediaPlaybackRequiresUserGesture: false,
  );

  WebViewController? webViewFlutterController;

  Timer? _webProgressTimer;

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
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
    if (widget.embed.plugin.useIframe) {
      webViewFlutterController?.loadHtmlString(widget.embed.playableIframe);
    } else {
      webViewFlutterController?.loadRequest(Uri.parse(widget.embed.requestUrl));
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
      });
    }
  }

  Future<bool> askToExit() async {
    bool accepted = await showPromptDialog(
      context,
      title: "Are you want to exit this page?",
    );
    return accepted;
  }

  Future exitIfYes() async {
    bool isYes = await showPromptDialog(
      context,
      title: "Are you want to exit this page?",
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

  @override
  void initState() {
    MerlMovieClientPlayer.setDeviceOrientationAndSystemUI();
    WakelockPlus.enable();
    if (widget.embed.plugin.webView == WebViewProviderType.webview_flutter) {
      createWebViewFlutterController();
    }
    webViewKey = GlobalKey();
    update();
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
                          url: WebUri(widget.embed.requestUrl),
                          headers: widget.embed.plugin.headers,
                        ),
                initialData:
                    widget.embed.plugin.useIframe
                        ? InAppWebViewInitialData(
                          data: widget.embed.playableIframe,
                          baseUrl: WebUri(widget.embed.requestUrl),
                        )
                        : null,
                initialSettings: settings,
                onProgressChanged:
                    (controller, progress) =>
                        onWebRequestProgress(progress.toDouble()),
                onLoadStop: onFlutterInAppWebViewLoadStop,
                shouldOverrideUrlLoading:
                    onFlutterInAppWebViewShouldOverrideUrlLoading,
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
