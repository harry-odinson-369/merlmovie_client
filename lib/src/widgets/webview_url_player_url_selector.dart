import 'package:flutter/material.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';

class WebViewURLsPlayerURLSelector extends StatelessWidget {
  final List<URLPlayerModel> urls;
  final URLPlayerModel current;
  const WebViewURLsPlayerURLSelector({
    super.key,
    required this.urls,
    required this.current,
  });

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
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              "URLs",
              textAlign: TextAlign.center,
              style: context.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                ...urls.build((e, i) {
                  bool selected = e.url == current.url;
                  Color color = selected ? Colors.blue : Colors.white;
                  return ListTile(
                    onTap:
                        () => Navigator.of(NavigatorKey.currentContext!).pop(e),
                    leading: Opacity(
                      opacity: selected ? 1 : 0,
                      child: Icon(Icons.done, color: color),
                    ),
                    title: Text(
                      "${i + 1}.  ${e.name}",
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
