import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';

class PlayerBottomControlsButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final void Function()? onTap;
  final double iconSize;
  final TextStyle? labelStyle;
  const PlayerBottomControlsButton({
    super.key,
    required this.icon,
    this.label,
    this.onTap,
    this.iconSize = 26,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: IconButton(
        onPressed: onTap,
        icon: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: Colors.white),
            SizedBox(width: 12),
            if (label != null)
              Text(
                label ?? "",
                style:
                    labelStyle ??
                    context.theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
