// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/helpers/themoviedb.dart';
import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/widgets/scroll_to_index.dart';

class PlayerSelectSimilarSheet extends StatefulWidget {
  final MovieModel? current;
  final List<MovieModel> similar;
  const PlayerSelectSimilarSheet({
    super.key,
    this.current,
    required this.similar,
  });

  @override
  State<PlayerSelectSimilarSheet> createState() =>
      _PlayerSelectSimilarSheetState();
}

class _PlayerSelectSimilarSheetState extends State<PlayerSelectSimilarSheet> {
  late AutoScrollController controller;

  void update() => mounted ? setState(() {}) : () {};

  @override
  void initState() {
    super.initState();
    controller = AutoScrollController(axis: Axis.vertical);
    update();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      int index = widget.similar.indexWhere(
        (e) => e.unique == widget.current?.unique,
      );
      if (index != -1) {
        controller.scrollToIndex(
          index,
          duration: const Duration(milliseconds: 150),
          preferPosition: AutoScrollPosition.middle,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.maxMobileWidth,
      constraints: BoxConstraints(maxHeight: context.screen.height * .9),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Similar",
                    style: context.theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              controller: controller,
              padding: EdgeInsets.symmetric(horizontal: 12),
              children: [
                ...widget.similar.build((e, i) {
                  bool isSelected = widget.current?.unique == e.unique;
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop(e);
                    },
                    child: AutoScrollTag(
                      index: i,
                      key: Key("quality_$i"),
                      controller: controller,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.white.withOpacity(.15)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: TheMovieDbApi.getImage(
                                    e.posterPath,
                                    TMDBImageSize.w300,
                                  ),
                                  width: 98,
                                  height: 144,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.real_title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.theme.textTheme.titleMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      e.overview,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      "${e.real_year}  •  ${e.voteAverage.toStringAsFixed(1)}/10",
                                      style: context.theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
