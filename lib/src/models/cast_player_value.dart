import 'package:video_player/video_player.dart';

class VideoPlayerValueModel {
  final int position;
  final int duration;
  final bool isBuffering;
  final bool isInitialized;
  final bool isCompleted;
  final double aspectRatio;
  final double volume;
  final bool isPlaying;
  final SizeModel size;
  final bool isLooping;
  final List<BufferedRange> buffered;
  final String? errorDescription;
  final double playbackSpeed;

  VideoPlayerValueModel({
    required this.position,
    required this.duration,
    required this.isBuffering,
    required this.isInitialized,
    required this.isCompleted,
    required this.aspectRatio,
    required this.volume,
    required this.isPlaying,
    required this.size,
    required this.isLooping,
    required this.buffered,
    required this.playbackSpeed,
    this.errorDescription,
  });

  factory VideoPlayerValueModel.parse(VideoPlayerController controller) {
    final value = controller.value;
    return VideoPlayerValueModel(
      position: value.position.inSeconds,
      duration: value.duration.inSeconds,
      isBuffering: value.isBuffering,
      isInitialized: value.isInitialized,
      isCompleted: value.isCompleted,
      aspectRatio: value.aspectRatio,
      volume: value.volume,
      isPlaying: value.isPlaying,
      size: SizeModel(height: value.size.height, width: value.size.width),
      isLooping: controller.value.isLooping,
      buffered:
          value.buffered.map((range) {
            return BufferedRange(
              start: range.start.inSeconds,
              end: range.end.inSeconds,
            );
          }).toList(),
      playbackSpeed: value.playbackSpeed,
      errorDescription: value.errorDescription,
    );
  }

  factory VideoPlayerValueModel.fromMap(Map<String, dynamic> map) {
    return VideoPlayerValueModel(
      position: map['position'] ?? 0,
      duration: map['duration'] ?? 0,
      isBuffering: map['is_buffering'] ?? false,
      isInitialized: map['is_initialized'] ?? false,
      isCompleted: map['is_completed'] ?? false,
      aspectRatio: (map['aspect_ratio'] ?? 1.0).toDouble(),
      volume: (map['volume'] ?? 1.0).toDouble(),
      isPlaying: map['is_playing'] ?? false,
      size: SizeModel.fromMap(map['size'] ?? {}),
      isLooping: map['is_looping'] ?? false,
      buffered:
          (map['buffered'] as List<dynamic>? ?? [])
              .map((e) => BufferedRange.fromMap(e))
              .toList(),
      playbackSpeed: map["playback_speed"] ?? 1,
      errorDescription: map['error_description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'position': position,
      'duration': duration,
      'is_buffering': isBuffering,
      'is_initialized': isInitialized,
      'is_completed': isCompleted,
      'aspect_ratio': aspectRatio,
      'volume': volume,
      'is_playing': isPlaying,
      'size': size.toMap(),
      'is_looping': isLooping,
      'buffered': buffered.map((e) => e.toMap()).toList(),
      'playback_speed': playbackSpeed,
      'error_description': errorDescription,
    };
  }
}

class SizeModel {
  final double height;
  final double width;

  SizeModel({required this.height, required this.width});

  factory SizeModel.fromMap(Map<String, dynamic> map) {
    return SizeModel(
      height: (map['height'] ?? 0.0).toDouble(),
      width: (map['width'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'height': height, 'width': width};
  }
}

class BufferedRange {
  final int start;
  final int end;

  BufferedRange({required this.start, required this.end});

  factory BufferedRange.fromMap(Map<String, dynamic> map) {
    return BufferedRange(start: map['start'] ?? 0, end: map['end'] ?? 0);
  }

  Map<String, dynamic> toMap() {
    return {'start': start, 'end': end};
  }
}
