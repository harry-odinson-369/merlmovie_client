// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/global/global.vars.dart';
import 'package:merlmovie_client/src/widgets/hyperlink.dart';

enum PromptDialogButton { noYes, cancelOk, ok }

Future<bool> showPromptDialog({
  required String title,
  String? subtitle,
  PromptDialogButton button = PromptDialogButton.noYes,
  TextStyle? titleStyle,
  TextStyle? subtitleStyle,
  Color? backgroundColor,
  bool scrollableSubtitle = false,
  TextStyle? negativeButtonTextStyle,
  TextStyle? positiveButtonTextStyle,
}) async {
  bool? accepted = await showDialog<bool?>(
    context: NavigatorKey.currentContext!,
    builder: (context) {
      return PromptDialog(
        title: title,
        subtitle: subtitle,
        button: button,
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        scrollableSubtitle: scrollableSubtitle,
        backgroundColor: backgroundColor,
        negativeButtonTextStyle: negativeButtonTextStyle,
        positiveButtonTextStyle: positiveButtonTextStyle,
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
  final TextStyle? negativeButtonTextStyle;
  final TextStyle? positiveButtonTextStyle;
  const PromptDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.button = PromptDialogButton.noYes,
    this.titleStyle,
    this.subtitleStyle,
    this.backgroundColor,
    this.scrollableSubtitle = false,
    this.negativeButtonTextStyle,
    this.positiveButtonTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [
      if (button == PromptDialogButton.noYes) ...[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            "NO",
            style:
                negativeButtonTextStyle ??
                context.theme.textTheme.titleMedium?.copyWith(
                  color: context.theme.textTheme.titleMedium?.color
                      ?.withOpacity(.8),
                ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            "YES",
            style:
                positiveButtonTextStyle ?? context.theme.textTheme.titleMedium,
          ),
        ),
      ],
      if (button == PromptDialogButton.cancelOk) ...[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            "CANCEL",
            style:
                negativeButtonTextStyle ??
                context.theme.textTheme.titleMedium?.copyWith(
                  color: context.theme.textTheme.titleMedium?.color
                      ?.withOpacity(.8),
                ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            "OK",
            style:
                positiveButtonTextStyle ?? context.theme.textTheme.titleMedium,
          ),
        ),
      ],
      if (button == PromptDialogButton.ok)
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            "OK",
            style:
                positiveButtonTextStyle ?? context.theme.textTheme.titleMedium,
          ),
        ),
    ];

    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: Text(title, style: titleStyle),
        content:
            subtitle == null
                ? null
                : ExpandCollapseText(
                  text: subtitle ?? "",
                  style: subtitleStyle,
                  collapsedMaxLines: 999,
                  textAlign: TextAlign.start,
                ),
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
                    child: ExpandCollapseText(
                      text: subtitle ?? "",
                      style: subtitleStyle,
                      textAlign: TextAlign.start,
                      collapsedMaxLines: 999,
                    ),
                  )
                  : ExpandCollapseText(
                    text: subtitle ?? "",
                    style: subtitleStyle,
                    collapsedMaxLines: 999,
                    textAlign: TextAlign.start,
                  ),
        ),
        actions: actions,
      );
    }
  }
}
