import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:video_player/video_player.dart';

enum VideoViewType { cropToFit, stretch, original }

class PlayerVideoBuilder extends StatelessWidget {
  final VideoPlayerController? controller;
  final VideoViewType viewType;
  const PlayerVideoBuilder({
    super.key,
    this.controller,
    this.viewType = VideoViewType.original,
  });

  @override
  Widget build(BuildContext context) {
    Widget videoView() {
      return controller != null
          ? VideoPlayer(controller!)
          : SizedBox(
            width: context.screen.width,
            height: context.screen.height,
          );
    }

    if (controller == null) {
      return SizedBox(
        width: context.screen.width,
        height: context.screen.height,
      );
    }
    return ValueListenableBuilder(
      valueListenable: controller!,
      builder: (context, value, _) {
        if (viewType == VideoViewType.original) {
          return AspectRatio(
            aspectRatio: value.aspectRatio,
            child: videoView(),
          );
        } else if (viewType == VideoViewType.cropToFit) {
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                height: value.size.height,
                width: value.size.width,
                child: videoView(),
              ),
            ),
          );
        } else {
          return videoView();
        }
      },
    );
  }
}
