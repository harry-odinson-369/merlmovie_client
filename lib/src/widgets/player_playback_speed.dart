import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/widgets/scroll_to_index.dart';

class PlayerPlaybackSpeed extends StatefulWidget {
  final void Function(double speed)? onPlaybackSpeedChanged;
  final double speed;
  const PlayerPlaybackSpeed({
    super.key,
    this.onPlaybackSpeedChanged,
    required this.speed,
  });

  @override
  State<PlayerPlaybackSpeed> createState() => _PlayerPlaybackSpeedState();
}

class _PlayerPlaybackSpeedState extends State<PlayerPlaybackSpeed> {

  final List<double> speed_arr = [
    3.0,
    2.5,
    2.0,
    1.5,
    1.25,
    1.0,
    0.75,
    0.5,
    0.25,
  ];

  late AutoScrollController controller;

  void update() => mounted ? setState(() {}) : () {};

  @override
  void initState() {
    super.initState();
    controller = AutoScrollController(axis: Axis.vertical);
    update();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      int index = speed_arr.indexWhere((e) => e == widget.speed);
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
                    "Playback Speed",
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
                ...speed_arr.build((e, i) {
                  bool isSelected = e == widget.speed;
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
                      key: Key("speed_$i"),
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
                              "${e == 1.0 ? "Normal" : e}",
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
