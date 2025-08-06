import 'package:merlmovie_client/src/models/embed.dart';

class LoadingModel {
  double progress = 0;
  EmbedModel embed;

  LoadingModel({this.progress = 0, required this.embed});

  factory LoadingModel.fromMap(Map<String, dynamic> map) => LoadingModel(
    progress: map["progress"] ?? 0,
    embed: EmbedModel.fromMap(map["embed"] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    "progress": progress,
    "embed": embed.toMap(),
  };
}
