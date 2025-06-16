import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/widgets/select_subtitle_child_listview.dart';
import 'package:merlmovie_client/src/widgets/select_subtitle_listview.dart';

class PlayerSelectSubtitle extends StatefulWidget {
  final List<SubtitleItem> subtitles;
  final SubtitleItem? current;
  final String? season, episode;
  const PlayerSelectSubtitle({
    super.key,
    required this.subtitles,
    this.current,
    this.season,
    this.episode,
  });

  @override
  State<PlayerSelectSubtitle> createState() => _PlayerSelectSubtitleState();
}

class _PlayerSelectSubtitleState extends State<PlayerSelectSubtitle> {
  PageController? controller;

  int pageIndex = 0;

  SubtitleItem? temp;

  void update() => mounted ? setState(() {}) : () {};

  void onSubtitleSelected(SubtitleItem? subtitle) {
    if (subtitle == null) {
      Navigator.of(context).pop(null);
      return;
    }
    if (subtitle.type == SubtitleRootType.normal) {
      if (subtitle != widget.current) {
        Navigator.of(context).pop(subtitle);
      } else {
        Navigator.of(context).pop(null);
      }
    } else {
      pageIndex = 1;
      temp = subtitle;
      controller?.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      update();
    }
  }

  void onSubtitleChildSelected(SubtitleItem? subtitle) {
    if (subtitle != widget.current) {
      Navigator.of(context).pop(subtitle);
    } else {
      Navigator.of(context).pop(null);
    }
  }

  void onSubtitleChildSelectionClosed(SubtitleItem newSubtitle) {
    pageIndex = 0;
    controller?.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    int index = widget.subtitles.indexWhere((e) => e.link == newSubtitle.link);
    if (index != -1) {
      widget.subtitles[index].children = newSubtitle.children;
    }
    if (temp?.link == newSubtitle.link) {
      temp?.children = newSubtitle.children;
    }
    update();
  }

  @override
  void initState() {
    super.initState();
    controller = PageController();
    update();
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
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
          if (pageIndex == 0)
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
                      "Subtitles",
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
            child: PageView(
              controller: controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SelectSubtitleListview(
                  subtitles: widget.subtitles,
                  current: widget.current,
                  onChanged: onSubtitleSelected,
                ),
                if (pageIndex == 1)
                  SelectSubtitleChildListview(
                    current: widget.current,
                    temp: temp!,
                    season: widget.season,
                    episode: widget.episode,
                    onClose: onSubtitleChildSelectionClosed,
                    onChanged: onSubtitleChildSelected,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
