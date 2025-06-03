import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/helpers/duration.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/widgets/player_bottom_controls_button.dart';
import 'package:merlmovie_client/src/widgets/player_playback_speed.dart';
import 'package:merlmovie_client/src/widgets/player_select_quality.dart';
import 'package:merlmovie_client/src/widgets/player_video_builder.dart';
import 'package:video_player/video_player.dart';

class PlayerBottomControls extends StatelessWidget {
  final VideoPlayerController? controller;
  final VideoViewType viewType;
  final double playbackSpeed;
  final QualityItem? quality;
  final int currentEpisode;
  final List<QualityItem> qualities;
  final List<Episode> episodes;
  final void Function(VideoViewType view)? onViewTypeChanged;
  final void Function(double speed)? onPlaybackSpeedChanged;
  final void Function(QualityItem quality)? onQualityChanged;
  final void Function(Episode episode)? onEpisodeChanged;
  final List<PlayerBottomControlsButton> Function(
    List<PlayerBottomControlsButton> buttons,
  )?
  buttons;
  const PlayerBottomControls({
    super.key,
    this.quality,
    this.currentEpisode = 0,
    this.qualities = const [],
    this.episodes = const [],
    this.buttons,
    this.controller,
    this.viewType = VideoViewType.original,
    this.playbackSpeed = 1.0,
    this.onQualityChanged,
    this.onViewTypeChanged,
    this.onPlaybackSpeedChanged,
    this.onEpisodeChanged,
  });

  void changeView() {
    if (viewType == VideoViewType.original) {
      onViewTypeChanged?.call(VideoViewType.cropToFit);
    } else if (viewType == VideoViewType.cropToFit) {
      onViewTypeChanged?.call(VideoViewType.stretch);
    } else {
      onViewTypeChanged?.call(VideoViewType.original);
    }
  }

  Future changePlaybackSpeed(BuildContext context, double playbackSpeed) async {
    double? speed = await showModalBottomSheet<double?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return PlayerPlaybackSpeed(speed: playbackSpeed);
      },
    );
    if (speed != null) {
      onPlaybackSpeedChanged?.call(speed);
    }
  }

  Future changeQuality(
    BuildContext context,
    QualityItem? current,
    List<QualityItem> qualities,
  ) async {
    QualityItem? quality = await showModalBottomSheet<QualityItem?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return PlayerSelectQuality(quality: current, qualities: qualities);
      },
    );
    if (quality != null) {
      onQualityChanged?.call(quality);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultButtons = [
      if (episodes.isNotEmpty)
        PlayerBottomControlsButton(
          icon: CupertinoIcons.rectangle_stack,
          label: "Episodes",
        ),
      if (qualities.isNotEmpty)
        PlayerBottomControlsButton(
          onTap: () => changeQuality(context, quality, qualities),
          icon: Icons.high_quality_outlined,
          label: "Qualities",
        ),
      PlayerBottomControlsButton(
        icon: Icons.subtitles_outlined,
        label: "Subtitles",
      ),
      PlayerBottomControlsButton(
        onTap: () => changeView(),
        icon:
            viewType == VideoViewType.original
                ? Icons.crop_5_4
                : viewType == VideoViewType.cropToFit
                ? Icons.crop_free
                : Icons.zoom_out_map_rounded,
        label:
            viewType == VideoViewType.original
                ? "Original"
                : viewType == VideoViewType.cropToFit
                ? "Crop to Fit"
                : "Stretch",
      ),
      PlayerBottomControlsButton(
        onTap: () => changePlaybackSpeed(context, playbackSpeed),
        icon: Icons.speed_rounded,
        label: "Playback Speed",
      ),
    ];

    Widget progressBar(
      Duration pos,
      Duration total,
      List<DurationRange> buffered,
    ) {
      return SizedBox(
        height: 12,
        child: ProgressBar(
          progress: pos,
          total: total,
          buffered: DurationUtility.getBufferedDuration(buffered),
          timeLabelLocation: TimeLabelLocation.sides,
          timeLabelType: TimeLabelType.remainingTime,
          timeLabelTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          barHeight: 8,
          thumbColor: Colors.red,
          progressBarColor: Colors.red,
          baseBarColor: Colors.grey.shade700,
          bufferedBarColor: Colors.grey.shade400,
          onSeek: (pos) => controller?.seekTo(pos),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        child: Column(
          children: [
            if (controller != null)
              ValueListenableBuilder(
                valueListenable: controller!,
                builder: (context, value, _) {
                  return progressBar(
                    value.position,
                    value.duration,
                    value.buffered,
                  );
                },
              ),
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: buttons?.call(defaultButtons) ?? defaultButtons,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
