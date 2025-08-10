import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/models/cast_landing.dart';
import 'package:merlmovie_client/src/extensions/context.dart';

class LandingBoard extends StatelessWidget {
  final LandingModel model;
  const LandingBoard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (model.appLogo.isNotEmpty)
          CachedNetworkImage(
            imageUrl: model.appLogo,
            fit: BoxFit.contain,
            height: context.screen.height * .35,
          ),
        if (model.appName.isNotEmpty)
          Text(
            model.appName,
            style: TextStyle(
              color: model.appNameColor,
              fontSize:
                  context.screen.height *
                  (model.appLogo.isNotEmpty ? .125 : .15),
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
