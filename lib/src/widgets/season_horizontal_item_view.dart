// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/helpers/themoviedb.dart';

class SeasonHorizontalItemView extends StatelessWidget {
  final Season season;
  final Color? textColor;
  const SeasonHorizontalItemView({
    super.key,
    required this.season,
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
                season.posterPath.startsWith("http")
                    ? season.posterPath
                    : TheMovieDbApi.getImage(
                      season.posterPath,
                      TMDBImageSize.w200,
                    ),
            width: 112,
            height: 168,
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
                  season.name.isNotEmpty &&
                          !season.name.toLowerCase().startsWith("season")
                      ? "${season.seasonNumber}. ${season.name}"
                      : "Season ${season.seasonNumber}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (season.overview.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      season.overview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: textColor?.withOpacity(.8),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "${season.episodes.length} episodes",
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
