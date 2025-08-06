import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/models/embed.dart';

class PlayerCastHolder extends StatelessWidget {
  final EmbedModel embed;
  const PlayerCastHolder({super.key, required this.embed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.screen.width,
      height: context.screen.height,
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cast_connected, size: 48),
          SizedBox(width: 24),
          Flexible(
            child: Text(
              embed.type == "tv"
                  ? "S${embed.season}E${embed.episode} - ${embed.title}"
                  : embed.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
