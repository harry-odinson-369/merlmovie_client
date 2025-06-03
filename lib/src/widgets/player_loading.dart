import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:merlmovie_client/src/models/plugin.dart';
import 'package:merlmovie_client/src/widgets/player.dart';
import 'package:merlmovie_client/src/widgets/player_over_loading.dart';
import 'package:merlmovie_client/src/widgets/player_top_controls.dart';

class PlayerLoading extends StatelessWidget {
  final List<PluginModel> plugins;
  final EmbedModel embed;
  final double progress;
  final String? sheetLabel;
  final void Function(PluginModel plugin)? onPluginChanged;
  const PlayerLoading({
    super.key,
    this.plugins = const [],
    required this.embed,
    required this.progress,
    this.onPluginChanged,
    this.sheetLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: PlayerOverLoading(progress: progress.toInt(), embed: embed),
        ),
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => PlayerTopControls.pop(context),
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  if (plugins.isNotEmpty)
                    IconButton(
                      onPressed: () async {
                        PluginModel? plugin = await MerlMovieClientPlayer.selectPlugin(
                              context,
                              plugins,
                              embed,
                              label: sheetLabel,
                            );
                        if (plugin != null) {
                          onPluginChanged?.call(plugin);
                        }
                      },
                      icon: Icon(
                        Icons.format_list_bulleted,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
