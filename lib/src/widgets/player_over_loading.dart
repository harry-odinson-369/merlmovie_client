// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/apis/client.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/models/embed.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayerOverLoading extends StatefulWidget {
  final int progress;
  final EmbedModel embed;
  const PlayerOverLoading({
    super.key,
    required this.progress,
    required this.embed,
  });

  @override
  State<PlayerOverLoading> createState() => _PlayerOverLoadingState();
}

class _PlayerOverLoadingState extends State<PlayerOverLoading> {
  bool show = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      show = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget loading = Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.progress == 0 && widget.embed.title.isEmpty)
          CircularProgressIndicator(
            color: Colors.blue,
            backgroundColor: Colors.grey.shade800,
          ),
        CircularProgressIndicator(
          color: Colors.blue,
          value: (widget.progress / 100),
          backgroundColor: Colors.grey.shade800,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: context.screen.width / 2,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: "Loading resource from ",
              style: context.theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              children: [
                TextSpan(
                  text: widget.embed.plugin.name,
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap =
                            () => launchUrl(
                              Uri.parse(widget.embed.plugin.website),
                            ),
                ),
                TextSpan(
                  text: " ${widget.progress}%",
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    double prog = widget.progress / 100;

    Widget textTitle = Text(
      widget.embed.title,
      textAlign: TextAlign.center,
      style: context.theme.textTheme.titleLarge?.copyWith(
        fontSize: context.screen.height * .125,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );

    Widget cachedImage = CachedNetworkImage(
      imageUrl: widget.embed.title_logo,
      fit: BoxFit.contain,
      cacheKey: widget.embed.key,
      placeholder: (context, url) => textTitle,
      errorWidget: (context, url, error) => textTitle,
    );

    return Container(
      height: context.screen.height,
      width: context.screen.width,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl:
                  CastClientController.instance.isConnected.value
                      ? "___"
                      : widget.embed.thumbnail,
              errorWidget:
                  (context, url, error) => Container(color: Colors.black),
              placeholder: (context, url) => Container(color: Colors.black),
              height: context.screen.height,
              width: context.screen.width,
              fit: BoxFit.cover,
            ),
          ),

          Container(
            width: context.screen.width,
            height: context.screen.height,
            color: Colors.black.withOpacity(.6),
          ),

          if (widget.embed.title_logo.isNotEmpty)
            SizedBox(
              width: (context.screen.width / 2.5),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: .4,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcATop,
                      ),
                      child: cachedImage,
                    ),
                  ),
                  if (prog == 0)
                    AnimatedOpacity(
                      opacity: show ? 1 : 0,
                      duration: Duration(milliseconds: 1000),
                      onEnd:
                          () => setState(() {
                            show = !show;
                          }),
                      child: cachedImage,
                    ),
                  if (prog > 0)
                    TweenAnimationBuilder(
                      duration: Duration(
                        milliseconds: 600,
                      ), // Animation duration
                      curve: Curves.easeInOut, // Smooth transition
                      tween: Tween<double>(begin: 0.0, end: prog),
                      builder: (context, animatedProgress, _) {
                        return ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: [animatedProgress, animatedProgress],
                              colors: [Colors.white, Colors.transparent],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: cachedImage,
                        );
                      },
                    ),
                ],
              ),
            ),

          if (widget.embed.title_logo.isEmpty) loading,
        ],
      ),
    );
  }
}
