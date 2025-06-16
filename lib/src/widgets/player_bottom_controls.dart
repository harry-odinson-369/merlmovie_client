import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/helpers/duration.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/widgets/player_bottom_controls_button.dart';
import 'package:merlmovie_client/src/widgets/player_playback_speed.dart';
import 'package:merlmovie_client/src/widgets/player_select_episode.dart';
import 'package:merlmovie_client/src/widgets/player_select_quality.dart';
import 'package:merlmovie_client/src/widgets/player_select_subtitle.dart';
import 'package:merlmovie_client/src/widgets/player_video_builder.dart';
import 'package:video_player/video_player.dart';

class PlayerBottomControls extends StatelessWidget {
  final VideoPlayerController? controller;
  final ValueNotifier<VideoViewBuilderType>? currentViewType;
  final double currentPlaybackSpeed;
  final QualityItem? currentQuality;
  final Episode? currentEpisode;
  final SubtitleItem? currentSubtitle;
  final List<QualityItem> qualities;
  final List<Season> seasons;
  final List<SubtitleItem> subtitles;
  final void Function(VideoViewBuilderType view)? onViewTypeChanged;
  final void Function(double speed)? onPlaybackSpeedChanged;
  final void Function(QualityItem quality)? onQualityChanged;
  final void Function(Episode episode)? onEpisodeChanged;
  final void Function(SubtitleItem? subtitle)? onSubtitleChanged;
  final void Function()? preventHideControls;
  const PlayerBottomControls({
    super.key,
    this.controller,
    this.currentQuality,
    this.currentEpisode,
    this.currentSubtitle,
    this.currentViewType,
    this.currentPlaybackSpeed = 1.0,
    this.qualities = const [],
    this.seasons = const [],
    this.subtitles = const [],
    this.onQualityChanged,
    this.onViewTypeChanged,
    this.onPlaybackSpeedChanged,
    this.onEpisodeChanged,
    this.onSubtitleChanged,
    this.preventHideControls,
  });

  void changeView(VideoViewBuilderType current) {
    preventHideControls?.call();
    if (current == VideoViewBuilderType.original) {
      onViewTypeChanged?.call(VideoViewBuilderType.cropToFit);
    } else if (current == VideoViewBuilderType.cropToFit) {
      onViewTypeChanged?.call(VideoViewBuilderType.stretch);
    } else {
      onViewTypeChanged?.call(VideoViewBuilderType.original);
    }
  }

  Future changePlaybackSpeed(BuildContext context, double playbackSpeed) async {
    preventHideControls?.call();
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
    preventHideControls?.call();
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

  Future changeEpisode(
    BuildContext context,
    List<Season> seasons,
    Episode? current,
  ) async {
    preventHideControls?.call();
    Episode? episode = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return PlayerSelectEpisodeSheet(
          seasons: seasons,
          currentEpisode: current,
        );
      },
    );
    if (episode != null) {
      onEpisodeChanged?.call(episode);
    }
  }

  Future changeSubtitle(
    BuildContext context,
    List<SubtitleItem> subtitles,
    SubtitleItem? current,
  ) async {
    preventHideControls?.call();
    SubtitleItem? subtitle = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return PlayerSelectSubtitle(
          subtitles: subtitles,
          current: current,
          season: currentEpisode?.seasonNumber.toString(),
          episode: currentEpisode?.episodeNumber.toString(),
        );
      },
    );
    onSubtitleChanged?.call(subtitle);
  }

  @override
  Widget build(BuildContext context) {
    final defaultButtons = [
      if (seasons.isNotEmpty)
        PlayerBottomControlsButton(
          onTap: () {
            final sea = seasons.firstWhereOrNull(
              (e) => e.seasonNumber == currentEpisode?.seasonNumber,
            );
            final epi = sea?.episodes.firstWhereOrNull(
              (e) => e.episodeNumber == currentEpisode?.episodeNumber,
            );
            changeEpisode(context, seasons, epi);
          },
          icon: CupertinoIcons.rectangle_stack,
          iconSize: 22,
          label: "Episodes",
        ),
      if (qualities.isNotEmpty)
        PlayerBottomControlsButton(
          onTap: () => changeQuality(context, currentQuality, qualities),
          icon: Icons.high_quality_outlined,
          label: "Qualities",
        ),
      if (subtitles.isNotEmpty)
        PlayerBottomControlsButton(
          onTap: () => changeSubtitle(context, subtitles, currentSubtitle),
          icon: Icons.subtitles_outlined,
          label: "Subtitles",
        ),
      if (currentViewType != null)
        ValueListenableBuilder(
          valueListenable: currentViewType!,
          builder: (context, viewType, _) {
            return PlayerBottomControlsButton(
              onTap: () => changeView(viewType),
              icon:
                  viewType == VideoViewBuilderType.original
                      ? Icons.crop_5_4
                      : viewType == VideoViewBuilderType.cropToFit
                      ? Icons.crop_free
                      : Icons.zoom_out_map_rounded,
              label:
                  viewType == VideoViewBuilderType.original
                      ? "Original"
                      : viewType == VideoViewBuilderType.cropToFit
                      ? "Crop to Fit"
                      : "Stretch",
            );
          },
        ),
      PlayerBottomControlsButton(
        onTap: () => changePlaybackSpeed(context, currentPlaybackSpeed),
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
          thumbColor: context.theme.colorScheme.primary,
          progressBarColor: context.theme.colorScheme.primary,
          baseBarColor: Colors.grey.shade700,
          bufferedBarColor: Colors.grey.shade400,
          onSeek: (pos) {
            preventHideControls?.call();
            controller?.seekTo(pos);
          },
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
              child: Row(children: defaultButtons),
            ),
          ],
        ),
      ),
    );
  }
}
