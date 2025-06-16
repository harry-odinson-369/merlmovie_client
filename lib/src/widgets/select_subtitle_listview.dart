import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/widgets/scroll_to_index.dart';

class SelectSubtitleListview extends StatefulWidget {
  final List<SubtitleItem> subtitles;
  final SubtitleItem? current;
  final void Function(SubtitleItem? subtitle)? onChanged;
  const SelectSubtitleListview({
    super.key,
    required this.subtitles,
    this.onChanged,
    this.current,
  });

  @override
  State<SelectSubtitleListview> createState() => _SelectSubtitleListviewState();
}

class _SelectSubtitleListviewState extends State<SelectSubtitleListview> {
  late AutoScrollController autoScrollController;

  void update() => mounted ? setState(() {}) : () {};

  @override
  void initState() {
    super.initState();
    autoScrollController = AutoScrollController(axis: Axis.vertical);
    update();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      int index = widget.subtitles.indexWhere((e) => e.link == widget.current?.link);
      if (index != -1) {
        autoScrollController.scrollToIndex(
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
    autoScrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      controller: autoScrollController,
      padding: EdgeInsets.symmetric(horizontal: 12),
      children: [
        InkWell(
          onTap: () {
            widget.onChanged?.call(null);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(width: 24),
                if (widget.current == null)
                  Icon(
                    Icons.done,
                    size: 26,
                    color: Colors.white,
                  ),
                if (widget.current != null) SizedBox(width: 26),
                SizedBox(width: 24),
                Flexible(
                  child: Text(
                    "Off",
                    maxLines: 2,
                    style: context.theme.textTheme.titleMedium
                        ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...widget.subtitles.build((e, i) {
          bool isSelected = widget.current?.link == e.link;
          return InkWell(
            onTap: () => widget.onChanged?.call(e),
            child: AutoScrollTag(
              index: i,
              key: Key("subtitle_$i"),
              controller: autoScrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    SizedBox(width: 24),
                    if (isSelected)
                      Icon(Icons.done, size: 26, color: Colors.white),
                    if (!isSelected) SizedBox(width: 26),
                    SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        e.name,
                        maxLines: 2,
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (e.type == SubtitleRootType.fetch)
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        SizedBox(height: 60),
      ],
    );
  }
}
