import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

bool _isPaused = false;

class PlayerPlayPause extends StatefulWidget {
  final VideoPlayerController? controller;
  final double size;
  const PlayerPlayPause({super.key, this.controller, this.size = 72});

  @override
  State<PlayerPlayPause> createState() => _PlayerPlayPauseState();
}

class _PlayerPlayPauseState extends State<PlayerPlayPause>
    with SingleTickerProviderStateMixin {
  bool isBuffering = false;

  late AnimationController _animationController;

  void playPause() {
    if (widget.controller != null) {
      if (widget.controller!.value.isPlaying) {
        widget.controller?.pause();
        _isPaused = true;
        _animationController.animateTo(0.0);
      } else {
        widget.controller?.play();
        _isPaused = false;
        _animationController.animateTo(1.0);
      }
    }
  }

  void listener() {
    if (widget.controller != null) {
      final value = widget.controller!.value;
      final buffer = value.buffered.lastOrNull?.end.inMilliseconds;
      final position = value.position.inMilliseconds;
      bool buffering = position == buffer;
      if (widget.controller?.value.isPlaying == true) {
        _animationController.animateTo(1.0);
      } else {
        _animationController.animateTo(0.0);
      }
      isBuffering = buffering;
      if (mounted) setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: widget.controller?.value.isPlaying == true ? 1.0 : 0.0,
    );
    if (widget.controller != null) {
      widget.controller?.addListener(listener);
      isBuffering = widget.controller!.value.isBuffering;
      if (widget.controller!.value.isCompleted) {
        _isPaused = widget.controller!.value.isCompleted;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller?.removeListener(listener);
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: playPause,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child:
          widget.controller?.value.hasError == true
              ? Icon(Icons.error, size: widget.size, color: Colors.redAccent)
              : AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    ((widget.controller == null ||
                                isBuffering ||
                                widget.controller?.value.isInitialized ==
                                    false) &&
                            !_isPaused)
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
                          progress: _animationController,
                          size: widget.size * 1.4,
                          color: Colors.white,
                        ),
              ),
    );
  }
}
