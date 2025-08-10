import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merlmovie_client/src/apis/client.dart';
import 'package:merlmovie_client/src/extensions/seasons.dart';
import 'package:merlmovie_client/src/helpers/assets.dart';
import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/widgets/bounce.dart';
import 'package:merlmovie_client/src/widgets/player_play_pause.dart';
import 'package:video_player/video_player.dart';

class PlayerMiddleControls extends StatelessWidget {
  final VideoPlayerController? controller;
  final void Function()? preventHideControls;
  final ValueNotifier<bool> isInitializing;
  final AnimationController? animationController;
  final Episode? currentEp;
  final List<Season> seasons;
  final String mediaType;
  final void Function(Episode? next)? onNextEpisodeClicked;
  const PlayerMiddleControls({
    super.key,
    this.controller,
    this.preventHideControls,
    this.animationController,
    this.currentEp,
    this.seasons = const [],
    this.mediaType = "movie",
    this.onNextEpisodeClicked,
    required this.isInitializing,
  });

  Future forward15Second() async {
    if (CastClientController.instance.isConnected.value) {
      CastClientController.instance.forward();
    } else {
      goPosition(
        (currentPosition) => currentPosition + const Duration(seconds: 15),
      );
    }
  }

  Future rewind15Second() async {
    if (CastClientController.instance.isConnected.value) {
      CastClientController.instance.rewind();
    } else {
      goPosition(
        (currentPosition) => currentPosition - const Duration(seconds: 15),
      );
    }
  }

  Future goPosition(Duration Function(Duration currentPosition) builder) async {
    preventHideControls?.call();
    if (controller != null) {
      final currentPosition = await controller?.position;
      final newPosition = builder(currentPosition!);
      await controller?.seekTo(newPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    Episode? nextEpisode = seasons.findNextEpisode(currentEp);
    bool isNext = controller?.value.isCompleted == true && mediaType == "tv";
    bool shouldNextEpisode = nextEpisode != null && isNext;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: shouldNextEpisode ? 184 : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                "15",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              HalfCircleBounce(
                onTap: () => rewind15Second(),
                duration: const Duration(milliseconds: 200),
                direction: HalfCircleBounceDirection.left,
                child: SvgPicture.asset(
                  AssetsHelper.asset("assets/icons/svg/arrow_rotate_left.svg"),
                  width: 50,
                  height: 50,
                  colorFilter: ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcATop,
                  ),
                ),
              ),
            ],
          ),
        ),
        PlayerPlayPause(
          controller: controller,
          preventHideControls: preventHideControls,
          isInitializing: isInitializing,
          animationController: animationController,
        ),
        if (shouldNextEpisode)
          InkWell(
            onTap: () => onNextEpisodeClicked?.call(nextEpisode),
            child: SizedBox(
              width: 184,
              child: Row(
                children: [
                  Text(
                    "Next Episode",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.skip_next, size: 60, color: Colors.white),
                ],
              ),
            ),
          ),
        if (mediaType == "movie" || !shouldNextEpisode)
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                "15",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              HalfCircleBounce(
                onTap: () => forward15Second(),
                duration: const Duration(milliseconds: 200),
                direction: HalfCircleBounceDirection.right,
                child: Transform.flip(
                  flipX: true,
                  child: SvgPicture.asset(
                    AssetsHelper.asset(
                      "assets/icons/svg/arrow_rotate_left.svg",
                    ),
                    width: 50,
                    height: 50,
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcATop,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
