import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/merlmovie_client.dart';
import 'package:merlmovie_client/src/models/wss.dart';
import 'package:merlmovie_client/src/providers/browser.dart';
import 'package:merlmovie_client/src/providers/player_state.dart';
import 'package:merlmovie_client/src/widgets/browser.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Widget MerlMovieClientProvider({
  required List<SingleChildWidget> providers,
  required Widget child,
}) => MultiProvider(
  providers: [
    ...providers,
    ChangeNotifierProvider<PlayerStateProvider>(
      create: (context) => PlayerStateProvider(),
    ),
    ChangeNotifierProvider<BrowserProvider>(
      create: (context) => BrowserProvider(),
    ),
  ],
  child: child,
);

class MerlMovieClientBrowserBuilder extends StatelessWidget {
  final Widget? child;
  final Widget? floatingWidget;
  const MerlMovieClientBrowserBuilder({
    super.key,
    required this.child,
    this.floatingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BrowserProvider>(
        builder: (context, virtual, _) {
          bool isVisible = virtual.info?.visible == BrowserWebVisible.yes;
          Widget webView(WSSBrowserWebDataModel browserInfo) => BrowserWidget(
            info: browserInfo,
            socket: MerlMovieClient.socket,
            onNavigationRequest: (url, isMainFrame) {
              return BrowserWidget.onNavigationRequestHandler(
                MerlMovieClient.socket,
                url,
                isMainFrame,
              );
            },
            onNavigationFinished: (url) {
              BrowserWidget.onNavigationFinishedHandler(
                MerlMovieClient.socket,
                url,
                browserInfo.id,
              );
            },
          );
          return Stack(
            children: [
              if (!isVisible && virtual.info != null)
                Positioned(
                  bottom:
                      -(context.screen.height + (context.screen.height / 2)),
                  top: 0,
                  right: 0,
                  left: 0,
                  child: webView(virtual.info!),
                ),
              Container(
                color: context.theme.scaffoldBackgroundColor,
                height: context.screen.height,
                width: context.screen.width,
              ),
              child ?? const SizedBox(),
              if (isVisible && virtual.info != null)
                Positioned(
                  bottom: 0,
                  top: 0,
                  right: 0,
                  left: 0,
                  child: webView(virtual.info!),
                ),
            ],
          );
        },
      ),
      floatingActionButton: floatingWidget,
    );
  }
}
