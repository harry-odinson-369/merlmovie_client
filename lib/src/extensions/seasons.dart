import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:merlmovie_client/src/models/movie.dart';

extension SeasonsExtension on List<Season> {
  Episode? findCurrentEpisode(EmbedModel embed) {
    if (embed.season.isEmpty && embed.episode.isEmpty) return null;
    final season = firstWhereOrNull(
      (e) => e.seasonNumber == int.parse(embed.season),
    );
    return season?.episodes.firstWhereOrNull(
      (e) => e.episodeNumber == int.parse(embed.episode),
    );
  }

  Episode? findNextEpisode(Episode? current) {
    if (current == null) return null;

    for (var sIndex = 0; sIndex < length; sIndex++) {
      final season = this[sIndex];

      for (var eIndex = 0; eIndex < season.episodes.length; eIndex++) {
        if (season.episodes[eIndex].unique == current.unique) {
          // If there's a next episode in the same season
          if (eIndex + 1 < season.episodes.length) {
            return season.episodes[eIndex + 1];
          }

          // Otherwise, check the first episode of the next season
          if (sIndex + 1 < length && this[sIndex + 1].episodes.isNotEmpty) {
            return this[sIndex + 1].episodes.first;
          }

          // No next episode found
          return null;
        }
      }
    }
    return null;
  }
}
