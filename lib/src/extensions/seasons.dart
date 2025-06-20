import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:merlmovie_client/src/models/movie.dart';

extension SeasonsExtension on List<Season> {
  Episode? findCurrentEpisode(EmbedModel embed) {
    if (embed.season.isEmpty && embed.episode.isEmpty) return null;
    final season = firstWhereOrNull((e) => e.seasonNumber == int.parse(embed.season));
    return season?.episodes.firstWhereOrNull((e) => e.episodeNumber == int.parse(embed.episode));
  }
}