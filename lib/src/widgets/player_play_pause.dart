import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

bool _isPaused = false;

class PlayerPlayPause extends StatefulWidget {
  final VideoPlayerController? controller;
  final double size;
  final void Function()? preventHideControls;
  const PlayerPlayPause({
    super.key,
    this.controller,
    this.size = 72,
    this.preventHideControls,
  });

  @override
  State<PlayerPlayPause> createState() => _PlayerPlayPauseState();
}

class _PlayerPlayPauseState extends State<PlayerPlayPause>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;

  void playPause() {
    if (widget.controller != null) {
      if (widget.controller!.value.isPlaying) {
        widget.controller?.pause();
        _isPaused = true;
        _animationController?.animateTo(0.0);
      } else {
        widget.controller?.play();
        _isPaused = false;
        _animationController?.animateTo(1.0);
      }
    }
    widget.preventHideControls?.call();
  }

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: widget.controller?.value.isPlaying == true ? 1.0 : 0.0,
    );
    if (widget.controller != null) {
      if (widget.controller!.value.isCompleted) {
        _isPaused = widget.controller!.value.isCompleted;
      }
    }
    if (mounted) setState(() {});
    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget circular = SizedBox(
      key: Key("__buffering"),
      width: widget.size * 1.4,
      height: widget.size * 1.4,
      child: const CircularProgressIndicator(color: Colors.white),
    );

    return InkWell(
      onTap: playPause,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: Builder(
        builder: (context) {
          if (widget.controller == null) {
            return circular;
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
                if (value.isPlaying == true) {
                  _animationController?.animateTo(1.0);
                } else {
                  _animationController?.animateTo(0.0);
                }

                bool isLoading =
                    (value.isBuffering || (!value.isInitialized && !_isPaused));

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      isLoading || _animationController == null
                          ? circular
                          : AnimatedIcon(
                            key: Key("__play_pause"),
                            icon: AnimatedIcons.play_pause,
                            progress: _animationController!,
                            size: widget.size * 1.4,
                            color: Colors.white,
                          ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
