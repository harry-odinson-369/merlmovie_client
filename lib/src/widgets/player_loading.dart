import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/global/global.vars.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/models/plugin.dart';
import 'package:merlmovie_client/src/widgets/player.dart';
import 'package:merlmovie_client/src/widgets/player_over_loading.dart';
import 'package:merlmovie_client/src/widgets/player_select_episode.dart';
import 'package:merlmovie_client/src/widgets/player_select_similar_sheet.dart';
import 'package:merlmovie_client/src/widgets/player_top_controls.dart';

class PlayerLoading extends StatelessWidget {
  final List<PluginModel> plugins;
  final EmbedModel embed;
  final double progress;
  final String? sheetLabel;
  final Episode? currentEpisode;
  final MovieModel? currentSimilar;
  final List<Season> seasons;
  final List<MovieModel> similar;
  final void Function(PluginModel plugin)? onPluginChanged;
  final void Function(Episode episode)? onEpisodeChanged;
  final void Function(MovieModel movie)? onSimilarChanged;
  const PlayerLoading({
    super.key,
    this.plugins = const [],
    required this.embed,
    required this.progress,
    this.onPluginChanged,
    this.sheetLabel,
    this.currentEpisode,
    this.currentSimilar,
    this.seasons = const [],
    this.similar = const [],
    this.onEpisodeChanged,
    this.onSimilarChanged,
  });

  void changePlugin(BuildContext context) async {
    PluginModel? plugin = await MerlMovieClientPlayer.selectPlugin(
      context,
      plugins,
      embed,
      label: sheetLabel,
    );
    if (plugin != null) {
      onPluginChanged?.call(plugin);
    }
  }

  Future changeEpisode(
    BuildContext context,
    List<Season> seasons,
    Episode? current,
  ) async {
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
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: PlayerOverLoading(progress: progress.toInt(), embed: embed),
        ),
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => PlayerTopControls.pop(context),
                    icon: Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                  const Spacer(),
                  if (plugins.isNotEmpty)
                    Row(
                      children: [
                        if (similar.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: IconButton(
                              onPressed:
                                  () => changeSimilar(
                                    context,
                                    similar,
                                    currentSimilar,
                                    seasons,
                                    currentEpisode,
                                  ),
                              icon: Icon(
                                CupertinoIcons.list_bullet_below_rectangle,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        if (seasons.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: IconButton(
                              onPressed:
                                  () => changeEpisode(
                                    context,
                                    seasons,
                                    currentEpisode,
                                  ),
                              icon: Icon(
                                CupertinoIcons.rectangle_stack,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        if (plugins.isNotEmpty)
                          IconButton(
                            onPressed: () => changePlugin(context),
                            icon: Icon(
                              Icons.format_list_bulleted,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
