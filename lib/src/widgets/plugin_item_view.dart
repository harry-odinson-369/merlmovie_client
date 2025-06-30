import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/models/plugin.dart';

class PluginItemView extends StatelessWidget {
  final PluginModel plugin;
  final bool isSelected;
  final void Function()? onTap;
  const PluginItemView({
    super.key,
    this.isSelected = false,
    required this.plugin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            SizedBox(width: 24),
            if (isSelected) Icon(Icons.done, size: 26, color: Colors.white),
            if (!isSelected) SizedBox(width: 26),
            SizedBox(width: 24),
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: plugin.logoBackgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: CachedNetworkImage(
                imageUrl: plugin.image,
                fit: BoxFit.contain,
                height: 38,
                width: 38,
                errorWidget:
                    (context, url, error) =>
                        Icon(Icons.link, size: 32, color: Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          plugin.name.substring(
                            0,
                            plugin.name.length > 16 ? 16 : plugin.name.length,
                          ),
                          maxLines: 1,
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 6),
                        child: Text(
                          "v${plugin.version}",
                          style: context.theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    plugin.mediaType == MediaType.multi
                        ? "Movie & TV shows"
                        : plugin.mediaType == MediaType.tv
                        ? "TV shows"
                        : "Movie",
                    style: context.theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
