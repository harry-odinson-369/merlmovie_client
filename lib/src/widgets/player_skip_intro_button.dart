// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/apis/client.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:video_player/video_player.dart';

class PlayerSkipIntroButton extends StatelessWidget {
  final VideoPlayerController controller;
  final VideoPlayerValue? playerValue;
  final QualityItem? currentQuality;
  const PlayerSkipIntroButton({
    super.key,
    required this.controller,
    this.playerValue,
    this.currentQuality,
  });

  @override
  Widget build(BuildContext context) {
    Widget builder(VideoPlayerValue value) {
      if (currentQuality?.skipIntro?.end != null &&
          value.position.inSeconds <
              currentQuality!.skipIntro!.end!.inSeconds &&
          value.isInitialized) {
        return SizedBox(
          height: 36,
          child: OutlinedButton(
            onPressed: () {
              if (CastClientController.instance.isConnected.value) {
                CastClientController.instance.seek(
                  currentQuality!.skipIntro!.end!,
                );
              } else {
                controller.seekTo(currentQuality!.skipIntro!.end!);
              }
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Skip Intro ",
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
                Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black),
              ],
            ),
          ),
        );
      }
      return SizedBox();
    }

    if (playerValue != null) return builder(playerValue!);

    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        return builder(value);
      },
    );
  }
}
