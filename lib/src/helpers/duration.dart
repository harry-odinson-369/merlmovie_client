import 'package:video_player/video_player.dart';

class DurationUtility {
  static Duration getBufferedDuration(List<DurationRange> buffered) {
    if (buffered.isEmpty) return Duration.zero;
    return buffered.last.end;
    // Option 2 (optional): Find the max `end` (in case ranges are out of order)
    // return buffered.map((r) => r.end).reduce((a, b) => a > b ? a : b);
  }

  static String getTimeString(int minute) {
    final int hour = minute ~/ 60;
    final int minutes = minute % 60;
    return '${hour > 0 ? "$hour hr${hour > 1 ? "s" : ""}  " : ""}$minutes min${minutes > 1 ? "s" : ""}';
  }
}
