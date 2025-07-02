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

  String get unique => "$type-$tmdbId-$imdbId-$season-$episode-${plugin.hashCode}";

  String get request_url {
    bool isUseTVEmbedUrl = (type == "tv" && plugin.tvEmbedUrl.isNotEmpty);
    String link = isUseTVEmbedUrl ? plugin.tvEmbedUrl : plugin.embedUrl;
    String mediaId = other_id.isNotEmpty ? other_id : (plugin.useIMDb ? imdbId : tmdbId);

    Map<String, dynamic> key_map = {
      "{t}": type,
      "{i}": mediaId,
      "{s}": season,
      "{e}": episode,
      "/{s}": season.isNotEmpty ? "/$season" : null,
      "/{e}": episode.isNotEmpty ? "/$episode" : null,
    };

    String replace(String input, String from, String to) => input.split(from).join(to);
    bool isShouldRemove(MapEntry<String, dynamic> entry) => entry.key.startsWith("/") && entry.value == null;

    for (MapEntry<String, dynamic> entry in key_map.entries) {
      if (entry.value != null) {
        link = replace(link, entry.key, entry.value);
      } else if (isShouldRemove(entry)) {
        link = replace(link, entry.key, "");
      }
    }

    return link;
  }

  bool get isWSS => request_url.startsWith("ws://") || request_url.startsWith("wss://");

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
          src="$request_url"
          frameborder="0"
        ></iframe>
      </body>
    </html>
    """;
  }
}
