// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/widgets/episode_horizontal_item_view.dart';
import 'package:merlmovie_client/src/widgets/scroll_to_index.dart';

class SelectEpisodeListview extends StatefulWidget {
  final Episode? current;
  final Season? currentSeason;
  final List<Episode> episodes;
  final void Function(Episode episode)? onChanged;
  final void Function()? onClose;
  final Color? textColor;
  const SelectEpisodeListview({
    super.key,
    this.current,
    this.currentSeason,
    required this.episodes,
    this.onChanged,
    this.onClose,
    this.textColor,
  });

  @override
  State<SelectEpisodeListview> createState() => _SelectEpisodeListviewState();
}

class _SelectEpisodeListviewState extends State<SelectEpisodeListview> {
  late AutoScrollController controller;

  void update() => mounted ? setState(() {}) : () {};

  @override
  void initState() {
    super.initState();
    controller = AutoScrollController(axis: Axis.vertical);
    update();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      int index = widget.episodes.indexWhere(
        (e) =>
            e.seasonNumber == widget.current?.seasonNumber &&
            e.episodeNumber == widget.current?.episodeNumber,
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => widget.onClose?.call(),
                icon: Icon(Icons.arrow_back, color: widget.textColor),
              ),
              if (widget.currentSeason != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      widget.currentSeason?.name.isNotEmpty == true &&
                              widget.currentSeason?.name
                                      .toLowerCase()
                                      .startsWith("season") ==
                                  false
                          ? "${widget.currentSeason?.seasonNumber}. ${widget.currentSeason?.name}"
                          : "Season ${widget.currentSeason?.seasonNumber}",
                      maxLines: 1,
                      style: context.theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                      ),
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
              ...widget.episodes.build((e, i) {
                bool isSelected =
                    widget.current?.seasonNumber == e.seasonNumber &&
                    widget.current?.episodeNumber == e.episodeNumber;
                return InkWell(
                  onTap: () => widget.onChanged?.call(e),
                  borderRadius: BorderRadius.circular(10),
                  splashFactory: NoSplash.splashFactory,
                  splashColor: Colors.transparent,
                  child: AutoScrollTag(
                    key: Key("episode_$i"),
                    index: i,
                    controller: controller,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? widget.textColor?.withOpacity(.15)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 12,
                        ),
                        child: EpisodeHorizontalItemView(
                          episode: e,
                          textColor: widget.textColor,
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
    );
  }
}
