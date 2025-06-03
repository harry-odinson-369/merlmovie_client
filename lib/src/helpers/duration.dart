import 'package:video_player/video_player.dart';

class DurationUtility {
  static Duration getBufferedDuration(List<DurationRange> buffered) {
    if (buffered.isEmpty) return Duration.zero;
    return buffered.last.end;
    // Option 2 (optional): Find the max `end` (in case ranges are out of order)
    // return buffered.map((r) => r.end).reduce((a, b) => a > b ? a : b);
  }
}