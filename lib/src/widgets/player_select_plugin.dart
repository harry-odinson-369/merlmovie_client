import 'package:flutter/material.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/widgets/plugin_item_view.dart';
import 'package:merlmovie_client/src/widgets/scroll_to_index.dart';

class PlayerSelectPlugin extends StatefulWidget {
  final List<PluginModel> plugins;
  final String? label;
  final EmbedModel embed;
  const PlayerSelectPlugin({
    super.key,
    required this.embed,
    required this.plugins,
    this.label,
  });

  @override
  State<PlayerSelectPlugin> createState() => _PlayerSelectPluginState();
}

class _PlayerSelectPluginState extends State<PlayerSelectPlugin> {
  late AutoScrollController controller;

  void update() => mounted ? setState(() {}) : () {};

  @override
  void initState() {
    super.initState();
    controller = AutoScrollController(axis: Axis.vertical);
    update();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      int index = widget.plugins.indexWhere((e) => e == widget.embed.plugin);
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
                    widget.label ?? "Sources",
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
                ...widget.plugins.build((e, i) {
                  bool isSelected = e == widget.embed.plugin;
                  return AutoScrollTag(
                    index: i,
                    key: Key("plugin_$i"),
                    controller: controller,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: PluginItemView(
                        onTap: () {
                          if (!isSelected) {
                            Navigator.of(context).pop(e);
                          } else {
                            Navigator.of(context).pop(null);
                          }
                        },
                        plugin: e,
                        isSelected: isSelected,
                        trailing:
                            isSelected
                                ? InkWell(
                                  onTap: () => Navigator.of(context).pop(e),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.restart_alt,
                                      color: Colors.blue,
                                    ),
                                  ),
                                )
                                : null,
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
