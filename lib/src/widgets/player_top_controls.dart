// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/merlmovie_client.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:merlmovie_client/src/widgets/prompt_dialog.dart';
import 'package:video_player/video_player.dart';

class PlayerTopControls extends StatelessWidget {
  final VideoPlayerController? controller;
  final EmbedModel embed;
  final Widget? trailing;
  final void Function()? onTrailingClicked;
  final void Function()? preventHideControls;
  final QualityItem? currentQuality;
  const PlayerTopControls({
    super.key,
    this.controller,
    required this.embed,
    this.trailing,
    this.onTrailingClicked,
    this.preventHideControls,
    this.currentQuality,
  });

  static Future pop(BuildContext context) async {
    bool isPop = await showPromptDialog(
      title: "Are you want to exit?",
      titleStyle: context.theme.textTheme.titleLarge?.copyWith(
        color: Colors.white,
      ),
      subtitleStyle: context.theme.textTheme.bodyMedium?.copyWith(
        color: Colors.white70,
      ),
      positiveButtonTextStyle: context.theme.textTheme.titleMedium?.copyWith(
        color: Colors.white,
      ),
      negativeButtonTextStyle: context.theme.textTheme.titleMedium?.copyWith(
        color: Colors.white.withOpacity(.8),
      ),
    );
    if (isPop) {
      Navigator.of(context).pop();
      MerlMovieClient.closeWSSConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, top: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SafeArea(
                top: false,
                bottom: false,
                child: IconButton(
                  onPressed: () {
                    preventHideControls?.call();
                    pop(context);
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    embed.title.isEmpty
                        ? "Playing Video"
                        : embed.type == "tv"
                        ? "S${embed.season}E${embed.episode} - ${embed.title}"
                        : embed.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                bottom: false,
                child: IconButton(
                  onPressed:
                      onTrailingClicked != null
                          ? () {
                            preventHideControls?.call();
                            onTrailingClicked?.call();
                          }
                          : null,
                  icon: trailing ?? SizedBox(width: 24),
                ),
              ),
            ],
          ),
          if (controller != null)
            ValueListenableBuilder(
              valueListenable: controller!,
              builder: (context, value, child) {
                if (currentQuality?.skipIntro?.end != null &&
                    value.position.inSeconds <
                        currentQuality!.skipIntro!.end!.inSeconds) {
                  return SizedBox(height: 48);
                }
                return SizedBox();
              },
            ),
        ],
      ),
    );
  }
}
