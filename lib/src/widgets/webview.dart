// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MerlMovieClientWebViewWidget extends StatefulWidget {
  final String link;
  const MerlMovieClientWebViewWidget({super.key, required this.link});

  @override
  State<MerlMovieClientWebViewWidget> createState() => _MerlMovieClientWebViewWidgetState();
}

class _MerlMovieClientWebViewWidgetState extends State<MerlMovieClientWebViewWidget> {
  WebViewController? controller;

  int progress = 0;

  String? url;

  void initialize() async {
    controller =
        WebViewController()
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (progress) {
                this.progress = progress;
                update();
              },
              onUrlChange: (change) {
                url = change.url;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.link));
    update();
  }

  @override
  void initState() {
    initialize();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    controller?.setNavigationDelegate(NavigationDelegate());
    controller?.loadRequest(Uri.parse("about:blank"));
    controller = null;
  }

  void update() => mounted ? setState(() {}) : () {};

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (controller != null && await controller!.canGoBack()) {
          await controller?.goBack();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade100,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.grey.shade100,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Platform.isAndroid ? Icons.arrow_back : CupertinoIcons.back,
              color: Colors.black,
            ),
          ),
          title: Text(
            (url ?? widget.link).replaceAll("https://", ""),
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: Opacity(
              opacity: progress == 100 ? 0 : 1,
              child: LinearProgressIndicator(
                value: progress / 100 * 1,
                backgroundColor: Colors.grey.shade400,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.redAccent,
                ),
                color: Colors.red,
              ),
            ),
          ),
        ),
        body:
            controller == null
                ? SizedBox()
                : Padding(
                  padding: EdgeInsets.only(
                    bottom: context.media.viewPadding.bottom,
                  ),
                  child: WebViewWidget(controller: controller!),
                ),
      ),
    );
  }
}
