import 'package:subtitle/subtitle.dart';

class CastSubtitle extends Subtitle {
  CastSubtitle({
    required super.start,
    required super.end,
    required super.data,
    required super.index,
  });

  factory CastSubtitle.fromMap(Map<String, dynamic> map) => CastSubtitle(
    start: Duration(milliseconds: map["start"] ?? 0),
    end: Duration(milliseconds: map["end"] ?? 0),
    data: map["data"] ?? "",
    index: map["index"] ?? 0,
  );

  factory CastSubtitle.parse(Subtitle subtitle) => CastSubtitle(
    start: subtitle.start,
    end: subtitle.end,
    data: subtitle.data,
    index: subtitle.index,
  );

  Map<String, dynamic> toMap() => {
    "start": start.inMilliseconds,
    "end": end.inMilliseconds,
    "data": data,
    "index": index,
  };
}
