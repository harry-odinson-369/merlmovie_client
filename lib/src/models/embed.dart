import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/models/plugin.dart';

class EmbedModel {
  String type = "movie";
  String tmdbId = "",
      imdbId = "",
      season = "",
      episode = "",
      title = "",
      thumbnail = "",
      title_logo = "",
      other_id = "";
  DetailModel detail;
  PluginModel plugin;

  EmbedModel({
    this.type = "movie",
    this.tmdbId = "",
    this.imdbId = "",
    this.title = "",
    this.thumbnail = "",
    this.season = "",
    this.episode = "",
    this.title_logo = "",
    required this.detail,
    required this.plugin,
  });

  factory EmbedModel.fromMap(Map<String, dynamic> map) => EmbedModel(
    title: map["title"] ?? "",
    title_logo: map["title_logo"] ?? "",
    thumbnail: map["thumbnail"] ?? "",
    tmdbId: map["tmdb_id"] ?? "",
    imdbId: map["imdb_id"] ?? "",
    type: map["type"] ?? "",
    season: map["season"] ?? "",
    episode: map["episode"] ?? "",
    detail: DetailModel.fromMap(map["detail"] ?? {}),
    plugin: PluginModel.fromMap(map["plugin"] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    "title": title,
    "title_logo": title_logo,
    "thumbnail": thumbnail,
    "tmdb_id": tmdbId,
    "imdb_id": imdbId,
    "type": type,
    "season": season,
    "episode": episode,
    "detail": detail.toJson(),
    "plugin": plugin.toMap(),
  };

  String get key => "$type-$tmdbId";

  String get unique =>
      "$type-$tmdbId-$imdbId-$season-$episode-${plugin.hashCode}";

  String get requestUrl =>
      plugin.getPlayableLink(type, tmdbId, imdbId, season, episode, other_id);

  bool get isWSS =>
      requestUrl.startsWith("ws://") || requestUrl.startsWith("wss://");

  String get playableIframe {
    return """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>MerlMovie</title>
        <style>
          html,
          body {
            width: 100%;
            height: 100%;
            overflow: hidden;
            margin: 0;
          }
    
          iframe {
            height: 100%;
            width: 100%;
          }
        </style>
      </head>
      <body>
        <iframe
          src="$requestUrl"
          frameborder="0"
        ></iframe>
      </body>
    </html>
    """;
  }
}
