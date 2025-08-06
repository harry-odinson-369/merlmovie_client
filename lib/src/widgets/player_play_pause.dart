import 'package:flutter/material.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:video_player/video_player.dart';

bool _isPaused = false;

class PlayerPlayPause extends StatefulWidget {
  final VideoPlayerController? controller;
  final double size;
  final void Function()? preventHideControls;
  final ValueNotifier<bool> isInitializing;
  final AnimationController? animationController;
  const PlayerPlayPause({
    super.key,
    this.controller,
    this.size = 72,
    this.preventHideControls,
    required this.isInitializing,
    this.animationController,
  });

  @override
  State<PlayerPlayPause> createState() => _PlayerPlayPauseState();
}

class _PlayerPlayPauseState extends State<PlayerPlayPause> {
  void playPause() {
    bool isConnected = CastClientController.instance.isConnected.value;
    if (widget.controller != null) {
      if (widget.controller!.value.isPlaying) {
        if (isConnected) {
          CastClientController.instance.pause();
        } else {
          widget.controller?.pause();
        }
        _isPaused = true;
        widget.animationController?.animateTo(0.0);
      } else {
        if (isConnected) {
          CastClientController.instance.play();
        } else {
          widget.controller?.play();
        }
        _isPaused = false;
        widget.animationController?.animateTo(1.0);
      }
    }
    widget.preventHideControls?.call();
  }

  void listener() {
    if (mounted) {
      if (widget.controller?.value.isPlaying == true) {
        widget.animationController?.animateTo(1.0);
      } else {
        widget.animationController?.animateTo(0.0);
      }
    }
  }

  @override
  void initState() {
    if (widget.controller?.value.isPlaying == true) {
      widget.animationController?.animateTo(1.0);
    } else {
      widget.animationController?.animateTo(0.0);
    }
    if (widget.controller != null) {
      if (widget.controller!.value.isCompleted) {
        _isPaused = widget.controller!.value.isCompleted;
      }
      widget.controller?.addListener(listener);
    }
    if (mounted) setState(() {});
    super.initState();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: playPause,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: Builder(
        builder: (context) {
          if (widget.controller == null) {
            return SizedBox(
              key: Key("__buffering_1"),
              width: widget.size * 1.4,
              height: widget.size * 1.4,
              child: const CircularProgressIndicator(color: Colors.white),
            );
          }
          return ValueListenableBuilder(
            valueListenable: widget.controller!,
            builder: (context, value, _) {
              if (value.hasError) {
                return Icon(
                  Icons.error,
                  size: widget.size,
                  color: Colors.redAccent,
                );
              } else {
                bool isLoading =
                    (value.isBuffering || (!value.isInitialized && !_isPaused));

                return ValueListenableBuilder(
                  valueListenable: widget.isInitializing,
                  builder: (context, isInitial, _) {
                    return AnimatedSwitcher(
                      key: Key("__play_pause_switcher"),
                      duration: const Duration(milliseconds: 300),
                      child:
                          isLoading ||
                                  widget.animationController == null ||
                                  isInitial
                              ? SizedBox(
                                key: Key("__buffering"),
                                width: widget.size * 1.4,
                                height: widget.size * 1.4,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                              : AnimatedIcon(
                                key: Key("__play_pause"),
                                icon: AnimatedIcons.play_pause,
                                progress: widget.animationController!,
                                size: widget.size * 1.4,
                                color: Colors.white,
                              ),
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}
