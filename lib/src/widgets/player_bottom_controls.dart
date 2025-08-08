import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/helpers/duration.dart';
import 'package:merlmovie_client/src/widgets/player_bottom_controls_button.dart';
import 'package:merlmovie_client/src/widgets/player_playback_speed.dart';
import 'package:merlmovie_client/src/widgets/player_select_episode.dart';
import 'package:merlmovie_client/src/widgets/player_select_quality.dart';
import 'package:merlmovie_client/src/widgets/player_select_similar_sheet.dart';
import 'package:merlmovie_client/src/widgets/player_select_subtitle.dart';
import 'package:video_player/video_player.dart';

class PlayerBottomControls extends StatelessWidget {
  final VideoPlayerController? controller;
  final ValueNotifier<VideoViewBuilderType>? currentViewType;
  final double currentPlaybackSpeed;
  final QualityItem? currentQuality;
  final Episode? currentEpisode;
  final SubtitleItem? currentSubtitle;
  final MovieModel? currentSimilar;
  final List<QualityItem> qualities;
  final List<Season> seasons;
  final List<SubtitleItem> subtitles;
  final List<MovieModel> similar;
  final void Function(VideoViewBuilderType view)? onViewTypeChanged;
  final void Function(double speed)? onPlaybackSpeedChanged;
  final void Function(QualityItem quality)? onQualityChanged;
  final void Function(Episode episode)? onEpisodeChanged;
  final void Function(SubtitleItem? subtitle)? onSubtitleChanged;
  final void Function(MovieModel movie)? onSimilarChanged;
  final void Function()? preventHideControls;
  final void Function()? onEditSubtitleThemeClicked;
  final void Function(bool? connected)? onBroadcastClicked;
  const PlayerBottomControls({
    super.key,
    this.controller,
    this.currentQuality,
    this.currentEpisode,
    this.currentSubtitle,
    this.currentViewType,
    this.currentSimilar,
    this.currentPlaybackSpeed = 1.0,
    this.qualities = const [],
    this.seasons = const [],
    this.subtitles = const [],
    this.similar = const [],
    this.onQualityChanged,
    this.onViewTypeChanged,
    this.onPlaybackSpeedChanged,
    this.onEpisodeChanged,
    this.onSubtitleChanged,
    this.onSimilarChanged,
    this.preventHideControls,
    this.onEditSubtitleThemeClicked,
    this.onBroadcastClicked,
  });

  void changeView(VideoViewBuilderType current) {
    preventHideControls?.call();
    if (current == VideoViewBuilderType.original) {
      onViewTypeChanged?.call(VideoViewBuilderType.crop);
    } else if (current == VideoViewBuilderType.crop) {
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

  Future changeSimilar(
    BuildContext context,
    List<MovieModel> similar,
    MovieModel? current, [
    List<Season> seasons = const [],
    Episode? currentEpisode,
  ]) async {
    MovieModel? selected = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return PlayerSelectSimilarSheet(similar: similar, current: current);
      },
    );
    if (selected != null) {
      if (selected.unique != current?.unique) {
        onSimilarChanged?.call(selected);
      } else {
        changeEpisode(NavigatorKey.currentContext!, seasons, currentEpisode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultButtons = [
      if (similar.isNotEmpty)
        PlayerBottomControlsButton(
          onTap:
              () => changeSimilar(
                context,
                similar,
                currentSimilar,
                seasons,
                currentEpisode,
              ),
          icon: CupertinoIcons.list_bullet_below_rectangle,
          iconSize: 22,
          label: "Similar",
        ),
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
                      : viewType == VideoViewBuilderType.crop
                      ? Icons.crop_free
                      : Icons.zoom_out_map_rounded,
              label:
                  viewType == VideoViewBuilderType.original
                      ? "Original"
                      : viewType == VideoViewBuilderType.crop
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
      ValueListenableBuilder(
        valueListenable: CastClientController.instance.isConnected,
        builder: (context, connected, child) {
          return PlayerBottomControlsButton(
            onTap: () async {
              bool? connect = await CastClientController.instance.toggleConnect();
              onBroadcastClicked?.call(connect);
            },
            icon: connected ? Icons.cast_connected : Icons.cast,
            label: "Broadcast",
          );
        },
      ),
      if (onEditSubtitleThemeClicked != null)
        PlayerBottomControlsButton(
          onTap: onEditSubtitleThemeClicked,
          icon: Icons.format_paint,
          label: "Subtitle Theme",
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
          onDragUpdate: (details) {
            preventHideControls?.call();
          },
          onSeek: (pos) {
            preventHideControls?.call();
            if (CastClientController.instance.isConnected.value) {
              CastClientController.instance.seek(pos);
            } else {
              controller?.seekTo(pos);
            }
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
            NotificationListener(
              onNotification: (notification) {
                preventHideControls?.call();
                return true;
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: defaultButtons),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
