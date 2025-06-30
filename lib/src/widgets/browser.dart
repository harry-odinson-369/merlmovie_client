import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:merlmovie_client/src/controllers/socket_controller.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/global/global.vars.dart';
import 'package:merlmovie_client/src/helpers/logger.dart';
import 'package:merlmovie_client/src/models/wss.dart';
import 'package:merlmovie_client/src/providers/browser.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class BrowserWidget extends StatefulWidget {
  final WSSBrowserWebDataModel info;
  final SocketController? socket;
  final Future<bool> Function(String url, bool isMainFrame) onNavigationRequest;
  final void Function(String url) onNavigationFinished;
  final void Function()? onDismiss;
  const BrowserWidget({
    super.key,
    required this.info,
    required this.socket,
    required this.onNavigationRequest,
    required this.onNavigationFinished,
    this.onDismiss,
  });

  static Future<String> getCookie(String url) async {
    final cookieManager = CookieManager();
    final cookies = await cookieManager.getCookies(url: WebUri(url));
    return cookies.map((e) => "${e.name}=${e.value}").toList().join("; ");
  }

  static Future setCookie(String url, String cookie) async {
    final cookieManager = CookieManager();
    for (final co in cookie.split("; ")) {
      await cookieManager.setCookie(
        url: WebUri(url),
        name: co.split("=")[0],
        value: co.split("=")[1],
      );
    }
  }

  static String get uniqueId {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(30, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static Future<bool> onNavigationRequestHandler(
    SocketController? socket,
    String url,
    bool isMainFrame,
  ) async {
    final id = uniqueId;
    Completer<bool> completer = Completer<bool>();
    StreamSubscription<dynamic>? subscription = socket?.message?.listen((
      event,
    ) {
      final decoded = json.decode(event.toString());
      final wss = WSSDataModel.fromMap(decoded);
      if (wss.action == WSSAction.browser_result) {
        if (wss.id == null) {
          completer.finish(wss.data["allow"] ?? true);
        } else if (wss.id == id) {
          completer.finish(wss.data["allow"] ?? true);
        }
      }
    });
    String encoded = json.encode(
      WSSDataModel(
        action: WSSAction.browser_url_request,
        id: id,
        data: {"url": url, "is_main_frame": isMainFrame},
      ).toMap(),
    );
    socket?.sendMessage(encoded);
    bool isAllow = await completer.future;
    await subscription?.cancel();
    return isAllow;
  }

  static void onNavigationFinishedHandler(
    SocketController? socket,
    String url,
    String? id,
  ) {
    String encoded = json.encode(
      WSSDataModel(
        action: WSSAction.browser_url_finished,
        id: id,
        data: {"url": url},
      ).toMap(),
    );
    socket?.sendMessage(encoded);
  }

  @override
  State<BrowserWidget> createState() => _BrowserWidgetState();
}

class _BrowserWidgetState extends State<BrowserWidget> {
  WebViewController? controller0;
  InAppWebViewController? controller1;

  StreamSubscription<dynamic>? subscription;

  Future initializeWeb0() async {
    if (Platform.isIOS) {
      WebKitWebViewController wk = WebKitWebViewController(
        WebKitWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
          const PlatformWebViewControllerCreationParams(),
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{
            PlaybackMediaTypes.audio,
          },
        ),
      );
      controller0 = WebViewController.fromPlatform(wk);
    } else {
      AndroidWebViewController wk = AndroidWebViewController(
        AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
          PlatformWebViewControllerCreationParams(),
        ),
      );
      wk.setMediaPlaybackRequiresUserGesture(true);
      controller0 = WebViewController.fromPlatform(wk);
      (controller0!.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    controller0?.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller0?.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) async {
          bool isAllow = await widget.onNavigationRequest(
            request.url,
            request.isMainFrame,
          );
          return isAllow
              ? NavigationDecision.navigate
              : NavigationDecision.prevent;
        },
        onPageFinished: (url) async {
          widget.onNavigationFinished(url);
        },
      ),
    );
    controller0?.loadRequest(
      Uri.parse(widget.info.url),
      headers: widget.info.headers ?? <String, String>{},
    );
    if (mounted) setState(() {});
  }

  Future<String> evaluate(String script) async {
    try {
      if (widget.info.type == BrowserWebType.web_0) {
        final result = await controller0?.runJavaScriptReturningResult(script);
        return result.toString();
      } else {
        final result = await controller1?.evaluateJavascript(source: script);
        return result.toString();
      }
    } catch (_) {
      return "";
    }
  }

  void click(Offset offset) {
    String script = """
      const __xele__ = document.elementFromPoint(${offset.dx}, ${offset.dy});
      if (__xele__) {
        const __xeve = new MouseEvent('click', {
          view: window,
          bubbles: true,
          cancelable: true,
          clientX: ${offset.dx},
          clientY: ${offset.dy}
        });
        __xele__.dispatchEvent(__xeve);
      }
    """;
    if (widget.info.type == BrowserWebType.web_0) {
      controller0?.runJavaScript(script);
    } else {
      controller1?.evaluateJavascript(source: script);
    }
  }

  void onMessage(dynamic event) async {
    final decoded = json.decode(event.toString());
    final wss = WSSDataModel.fromMap(decoded);

    if (wss.action == WSSAction.browser_evaluate) {
      final result = await evaluate(wss.data["script"]);
      final data = WSSDataModel(
        action: WSSAction.browser_evaluate_result,
        data: {"result": result},
        id: wss.id,
      );
      widget.socket?.sendMessage(json.encode(data.toMap()));
    } else if (wss.action == WSSAction.browser_click) {
      final offset = Offset(
        double.parse(wss.data["x"].toString()),
        double.parse(wss.data["y"].toString()),
      );
      click(offset);
    }
  }

  @override
  void initState() {
    super.initState();
    LoggerHelper.logMsg("[Browser] Spawning new instance...");
    if (widget.info.type == BrowserWebType.web_0) {
      initializeWeb0();
    }
    subscription = widget.socket?.message?.listen(onMessage);
  }

  @override
  void dispose() {
    super.dispose();
    controller0?.setNavigationDelegate(NavigationDelegate());
    controller0?.loadRequest(Uri.parse("about:blank"));
    controller0 = null;
    controller1?.dispose();
    subscription?.cancel();
    subscription = null;
    LoggerHelper.logMsg("[Browser] Instance closed!");
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (controller0 != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 0,
            child: SizedBox(
              height: context.screen.height,
              width: context.screen.width,
              child: WebViewWidget(controller: controller0!),
            ),
          ),
        if (widget.info.type == BrowserWebType.web_1)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 0,
            child: SizedBox(
              height: context.screen.height,
              width: context.screen.width,
              child: InAppWebView(
                onWebViewCreated: (controller) {
                  controller1 = controller;
                  if (mounted) setState(() {});
                },
                initialUrlRequest: URLRequest(
                  url: WebUri(widget.info.url),
                  headers: widget.info.headers,
                ),
                initialSettings: InAppWebViewSettings(
                  allowsInlineMediaPlayback: true,
                  javaScriptEnabled: true,
                  mediaPlaybackRequiresUserGesture: true,
                  isInspectable: false,
                  allowBackgroundAudioPlaying: false,
                  useShouldOverrideUrlLoading: true,
                  useHybridComposition: true,
                ),
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  bool isAllow = await widget.onNavigationRequest(
                    navigationAction.request.url.toString(),
                    navigationAction.isForMainFrame,
                  );
                  return isAllow
                      ? NavigationActionPolicy.ALLOW
                      : NavigationActionPolicy.CANCEL;
                },
                onLoadStop: (controller, url) async {
                  controller1 = controller;
                  widget.onNavigationFinished(url.toString());
                },
              ),
            ),
          ),
        Positioned(
          right: 12,
          top: 12,
          child: SafeArea(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(99),
              ),
              child: InkWell(
                onTap: () async {
                  NavigatorKey.currentContext?.read<BrowserProvider>().close();
                  await Future.delayed(const Duration(milliseconds: 300));
                  widget.onDismiss?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
