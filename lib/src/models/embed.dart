import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/models/plugin.dart';

class EmbedModel {
  String type = "movie";
  String tmdbId = "";
  String imdbId = "";
  String? season, episode, title, thumbnail, title_logo, other_id;
  DetailModel? detail;
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
