import 'package:flutter/material.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/widgets/plugin_item_view.dart';

class SelectPlugins extends StatelessWidget {
  final List<PluginModel> plugins;
  final String? label;
  final EmbedModel embed;
  const SelectPlugins({
    super.key,
    required this.embed,
    required this.plugins,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.maxMobileWidth + 200,
      constraints: BoxConstraints(maxHeight: context.screen.height * .9),
      padding: EdgeInsets.only(bottom: 24),
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
                    label ?? "Plugins",
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
              padding: EdgeInsets.symmetric(horizontal: 12),
              children: [
                ...plugins.map((e) {
                  bool isSelected = e == embed.plugin;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: PluginItemView(
                      plugin: e,
                      isSelected: isSelected,
                      onTap: () {
                        if (!isSelected) {
                          Navigator.of(context).pop(e);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
