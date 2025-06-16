import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';

enum PromptDialogButton { noYes, cancelOk, ok }

Future<bool> showPromptDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  PromptDialogButton button = PromptDialogButton.noYes,
  TextStyle? titleStyle,
  TextStyle? subtitleStyle,
  Color? backgroundColor,
  bool scrollableSubtitle = false,
}) async {
  bool? accepted = await showDialog<bool?>(
    context: context,
    builder: (context) {
      return PromptDialog(
        title: title,
        subtitle: subtitle,
        button: button,
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        scrollableSubtitle: scrollableSubtitle,
        backgroundColor: backgroundColor,
      );
    },
  );
  await Future.delayed(const Duration(milliseconds: 300));
  return accepted == true;
}

class PromptDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final PromptDialogButton button;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color? backgroundColor;
  final bool scrollableSubtitle;
  const PromptDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.button = PromptDialogButton.noYes,
    this.titleStyle,
    this.subtitleStyle,
    this.backgroundColor,
    this.scrollableSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [
      if (button == PromptDialogButton.noYes) ...[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            "NO",
            style: context.theme.textTheme.titleMedium?.copyWith(
              color: context.theme.textTheme.titleMedium?.color?.withOpacity(
                .8,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text("YES", style: context.theme.textTheme.titleMedium),
        ),
      ],
      if (button == PromptDialogButton.cancelOk) ...[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            "CANCEL",
            style: context.theme.textTheme.titleMedium?.copyWith(
              color: context.theme.textTheme.titleMedium?.color?.withOpacity(
                .8,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text("OK", style: context.theme.textTheme.titleMedium),
        ),
      ],
      if (button == PromptDialogButton.ok)
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text("OK", style: context.theme.textTheme.titleMedium),
        ),
    ];

    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: Text(title, style: titleStyle),
        content:
            subtitle == null
                ? null
                : Text(subtitle ?? "", style: subtitleStyle),
        actions: actions,
      );
    } else {
      return AlertDialog(
        title: Text(title, style: titleStyle),
        backgroundColor: backgroundColor ?? Colors.grey.shade800,
        content: SizedBox(
          width: context.maxMobileWidth,
          child:
              subtitle == null
                  ? null
                  : scrollableSubtitle
                  ? SingleChildScrollView(
                    child: Text(subtitle ?? "", style: subtitleStyle),
                  )
                  : Text(subtitle ?? "", style: subtitleStyle),
        ),
        actions: actions,
      );
    }
  }
}
