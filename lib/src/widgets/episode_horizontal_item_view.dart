import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/helpers/duration.dart';
import 'package:merlmovie_client/src/helpers/themoviedb.dart';
import 'package:merlmovie_client/src/models/movie.dart';

class EpisodeHorizontalItemView extends StatelessWidget {
  final Episode episode;
  final Color? textColor;
  const EpisodeHorizontalItemView({
    super.key,
    required this.episode,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl:
                episode.stillPath.startsWith("http")
                    ? episode.stillPath
                    : TheMovieDbApi.getImage(
                      episode.stillPath,
                      TMDBImageSize.w300,
                    ),
            width: 158,
            height: 92,
            fit: BoxFit.cover,
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.name.isNotEmpty &&
                          !episode.name.toLowerCase().startsWith("episode")
                      ? "${episode.episodeNumber}. ${episode.name}"
                      : "Episode ${episode.seasonNumber}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (episode.overview.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      episode.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: textColor?.withOpacity(.8),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    DurationUtility.getTimeString(episode.runtime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
