import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/merlmovie_client.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:merlmovie_client/src/widgets/prompt_dialog.dart';
import 'package:video_player/video_player.dart';

class PlayerTopControls extends StatelessWidget {
  final VideoPlayerController? controller;
  final EmbedModel embed;
  final Widget? trailing;
  final void Function()? onTrailingClicked;
  const PlayerTopControls({
    super.key,
    this.controller,
    required this.embed,
    this.trailing,
    this.onTrailingClicked,
  });

  static Future pop(BuildContext context) async {
    bool isPop = await showPromptDialog(context, title: "Are you want to exit?");
    if (isPop) {
      Navigator.of(context).pop();
      MerlMovieClient.closeWSSConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SafeArea(
            bottom: false,
            child: IconButton(
              onPressed: () => pop(context),
              icon: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                embed.title ?? "Playing Video",
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
            bottom: false,
            child: IconButton(
              onPressed: onTrailingClicked,
              icon: trailing ?? SizedBox(width: 24),
            ),
          ),
        ],
      ),
    );
  }
}
