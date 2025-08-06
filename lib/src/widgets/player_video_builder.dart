import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:video_player/video_player.dart';

enum VideoViewBuilderType { crop, stretch, original }

class PlayerVideoBuilder extends StatelessWidget {
  final VideoPlayerController? controller;
  final ValueNotifier<VideoViewBuilderType> viewType;
  const PlayerVideoBuilder({
    super.key,
    this.controller,
    required this.viewType,
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
      valueListenable: viewType,
      builder: (context, viewBuilderType, _) {
        return ValueListenableBuilder(
          valueListenable: controller!,
          builder: (context, value, _) {
            if (viewBuilderType == VideoViewBuilderType.original) {
              return AspectRatio(
                aspectRatio: value.aspectRatio,
                child: videoView(),
              );
            } else if (viewBuilderType == VideoViewBuilderType.crop) {
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
      },
    );
  }
}
