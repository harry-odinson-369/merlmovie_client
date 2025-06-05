import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/widgets/scroll_to_index.dart';

class PlayerSelectQuality extends StatefulWidget {
  final QualityItem? quality;
  final List<QualityItem> qualities;
  const PlayerSelectQuality({super.key, this.quality, required this.qualities});

  @override
  State<PlayerSelectQuality> createState() => _PlayerSelectQualityState();
}

class _PlayerSelectQualityState extends State<PlayerSelectQuality> {
  late AutoScrollController controller;

  void update() => mounted ? setState(() {}) : () {};

  @override
  void initState() {
    super.initState();
    controller = AutoScrollController(axis: Axis.vertical);
    update();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      int index = widget.qualities.indexWhere(
        (e) => e.link == widget.quality?.link,
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
                    "Qualities",
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
                ...widget.qualities.build((e, i) {
                  bool isSelected = widget.quality?.link == e.link;
                  return InkWell(
                    onTap: () {
                      if (!isSelected) {
                        Navigator.of(context).pop(e);
                      } else {
                        Navigator.of(context).pop(null);
                      }
                    },
                    child: AutoScrollTag(
                      index: i,
                      key: Key("quality_$i"),
                      controller: controller,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(width: 24),
                            if (isSelected)
                              Icon(Icons.done, size: 26, color: Colors.white),
                            if (!isSelected) SizedBox(width: 26),
                            SizedBox(width: 24),
                            Text(
                              e.name,
                              style: context.theme.textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
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
