import 'package:flutter/material.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/widgets/scroll_to_index.dart';
import 'package:merlmovie_client/src/widgets/season_horizontal_item_view.dart';

class SelectSeasonListview extends StatefulWidget {
  final Season? current;
  final List<Season> seasons;
  final void Function(Season season)? onChanged;
  final Color? textColor;
  const SelectSeasonListview({
    super.key,
    this.current,
    required this.seasons,
    this.onChanged,
    this.textColor,
  });

  @override
  State<SelectSeasonListview> createState() => _SelectSeasonListviewState();
}

class _SelectSeasonListviewState extends State<SelectSeasonListview> {
  late AutoScrollController controller;

  void update() => mounted ? setState(() {}) : () {};

  @override
  void initState() {
    super.initState();
    controller = AutoScrollController(axis: Axis.vertical);
    update();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      int index = widget.seasons.indexWhere(
        (e) => e.seasonNumber == widget.current?.seasonNumber,
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
    return ListView(
      shrinkWrap: true,
      controller: controller,
      padding: EdgeInsets.symmetric(horizontal: 12),
      children: [
        ...widget.seasons.build((e, i) {
          if (e.seasonNumber == 0) {
            return SizedBox();
          }
          bool isSelected = widget.current?.seasonNumber == e.seasonNumber;
          return InkWell(
            onTap: () => widget.onChanged?.call(e),
            borderRadius: BorderRadius.circular(10),
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            child: AutoScrollTag(
              key: Key("season_$i"),
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
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                  child: SeasonHorizontalItemView(
                    season: e,
                    textColor: widget.textColor,
                  ),
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
