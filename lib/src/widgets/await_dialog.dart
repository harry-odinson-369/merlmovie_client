// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/extensions/context.dart';

Future<T?> showAwaitingDialog<T>(
  Future<T> Function() function, {
  String label = "Please wait...",
  bool dismissible = true,
}) {
  if (Platform.isIOS) {
    return showCupertinoDialog<T>(
      context: NavigatorKey.currentContext!,
      barrierDismissible: dismissible,
      builder:
          (context) => AwaitingDialog(
            function: function,
            label: label,
            dismissible: dismissible,
          ),
    );
  }
  return showDialog<T>(
    context: NavigatorKey.currentContext!,
    barrierDismissible: dismissible,
    builder:
        (context) => AwaitingDialog(
          function: function,
          label: label,
          dismissible: dismissible,
        ),
  );
}

class AwaitingDialog extends StatefulWidget {
  final String label;
  final Future Function() function;
  final bool dismissible;
  const AwaitingDialog({
    super.key,
    required this.function,
    this.label = "Please wait...",
    this.dismissible = true,
  });

  @override
  State<AwaitingDialog> createState() => _AwaitingDialogState();
}

class _AwaitingDialogState extends State<AwaitingDialog> {
  @override
  void initState() {
    super.initState();
    widget.function().then((value) {
      if (mounted) {
        Navigator.of(context).pop(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Builder(
        builder: (context) {
          if (Platform.isIOS) {
            return CupertinoAlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(radius: 16),
                  SizedBox(height: 12),
                  Text(
                    widget.label,
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      color: context.theme.textTheme.titleMedium?.color
                          ?.withOpacity(.8),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return AlertDialog(
              backgroundColor: Colors.grey.shade800,
              actionsPadding: EdgeInsets.zero,
              contentPadding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 24,
              ),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: context.theme.textTheme.titleMedium?.color,
                    strokeWidth: 3,
                  ),
                  SizedBox(width: 16),
                  Text(
                    widget.label,
                    style: context.theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }
        },
      ),
      onWillPop: () async => widget.dismissible,
    );
  }
}
