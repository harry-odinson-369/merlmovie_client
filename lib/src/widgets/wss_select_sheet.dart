import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/global/global.vars.dart';
import 'package:merlmovie_client/src/models/wss.dart';

Future<WSSSelectModel?> showWSSSelectSheet(
  String title,
  List<WSSSelectModel> items,
) {
  return showModalBottomSheet<WSSSelectModel>(
    context: NavigatorKey.currentContext!,
    isScrollControlled: true,
    builder: (context) => WSSSelectSheet(title: title, items: items),
  );
}

class WSSSelectSheet extends StatelessWidget {
  final String title;
  final List<WSSSelectModel> items;
  const WSSSelectSheet({
    super.key,
    this.title = "Which One?",
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    bool isAllBanner = items.every(
      (e) => e.imageType == WSSSelectImageType.banner,
    );
    return Container(
      width: context.maxMobileWidth + (isAllBanner ? 74 : 0),
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
                    title,
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
                ...items.build((e, index) {
                  bool isBanner = e.imageType == WSSSelectImageType.banner;
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop(e);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: e.image,
                                width: isBanner ? 172 : 98,
                                height: isBanner ? 98 : 144,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.theme.textTheme.titleMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    e.subtitle,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.theme.textTheme.bodyMedium
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                ],
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
