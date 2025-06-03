import 'package:merlmovie_client/src/models/plugin.dart';

class EmbedModel {
  String type = "movie";
  String tmdbId = "";
  String imdbId = "";
  String? season, episode, title, thumbnail, title_logo;
  Map<String, dynamic>? detail;
  PluginModel plugin = PluginModel.fromMap({});

  EmbedModel({
    this.type = "movie",
    this.tmdbId = "",
    this.imdbId = "",
    this.title,
    this.thumbnail,
    this.season,
    this.episode,
    this.title_logo,
    this.detail,
    required this.plugin,
  });

  String get key => "$type-$tmdbId";

  String get unique => "$type-$tmdbId-$imdbId-$season-$episode-${plugin.hashCode}";

  String get requestUrl => plugin.getPlayableLink(type, tmdbId, imdbId, season, episode);

  bool get isWSS => requestUrl.startsWith("ws://") || requestUrl.startsWith("wss://");
}
