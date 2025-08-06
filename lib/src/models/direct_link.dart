import 'dart:convert';

import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/helpers/map.dart';

enum DirectLinkDataStatus { PROGRESS_STATUS, FINAL_RESULT, WEBVIEW_PLAYER }

enum SubtitleRootType { fetch, normal }

enum SubtitleFetchExtension { gz, zip, text }

class DirectLink {
  String title;
  String thumbnail;
  String sourceName;
  String website;
  DirectLinkDataStatus status;
  List<QualityItem> qualities = [];
  List<SubtitleItem> subtitles = [];
  Map<String, dynamic> payload;

  DirectLink({
    required this.title,
    required this.thumbnail,
    required this.sourceName,
    required this.website,
    required this.status,
    required this.qualities,
    required this.subtitles,
    required this.payload,
  });

  factory DirectLink.fromMap(Map<String, dynamic> map) => DirectLink(
    title: map["title"] ?? "",
    thumbnail: map["thumbnail"] ?? "",
    sourceName: map["source_name"] ?? "",
    website: map["website"] ?? "",
    status:
        DirectLinkDataStatus.values.firstWhereOrNull(
          (e) =>
              e.name.toLowerCase() ==
              (map["status"] ?? DirectLinkDataStatus.FINAL_RESULT.name)
                  .toString()
                  .toLowerCase(),
        ) ??
        DirectLinkDataStatus.FINAL_RESULT,
    qualities: List<QualityItem>.from(
      (map["qualities"] ?? []).map((e) => QualityItem.fromMap(e)),
    ),
    subtitles: List<SubtitleItem>.from(
      (map["subtitles"] ?? []).map((e) => SubtitleItem.fromMap(e)),
    ),
    payload: MapUtilities.convert<String, dynamic>(map["payload"]) ?? {},
  );

  factory DirectLink.fromWebUri(Uri uri) {
    var qualitiesEncoded = uri.queryParameters['qualities'];
    var subtitlesEncoded = uri.queryParameters['subtitles'];

    var status0 = uri.queryParameters["status"];

    var qualities0 = <QualityItem>[];
    var subtitles0 = <SubtitleItem>[];

    if (qualitiesEncoded != null) {
      var qualitiesJson = Uri.decodeComponent(qualitiesEncoded);
      qualities0 = List<QualityItem>.from(
        json.decode(qualitiesJson).map((e) => QualityItem.fromMap(e)),
      );
    }

    if (subtitlesEncoded != null) {
      var subtitlesJson = Uri.decodeComponent(subtitlesEncoded);
      subtitles0 = List<SubtitleItem>.from(
        json.decode(subtitlesJson).map((e) => SubtitleItem.fromMap(e)),
      );
    }

    return DirectLink(
      title: Uri.decodeComponent(uri.queryParameters["title"] ?? ""),
      thumbnail: Uri.decodeComponent(uri.queryParameters["thumbnail"] ?? ""),
      sourceName: Uri.decodeComponent(uri.queryParameters["source_name"] ?? ""),
      website: Uri.decodeComponent(uri.queryParameters["website"] ?? ""),
      qualities: qualities0,
      subtitles: subtitles0,
      status:
          DirectLinkDataStatus.values.firstWhereOrNull(
            (e) =>
                (e.name.toLowerCase()) ==
                (status0 ?? DirectLinkDataStatus.FINAL_RESULT.name)
                    .toString()
                    .toLowerCase(),
          ) ??
          DirectLinkDataStatus.FINAL_RESULT,
      payload: json.decode(uri.queryParameters["payload"] ?? "{}"),
    );
  }

  Map<String, dynamic> toMap() => {
    "title": title,
    "thumbnail": thumbnail,
    "source_name": sourceName,
    "website": website,
    "status": status.name,
    "qualities": qualities.map((e) => e.toMap()).toList(),
    "subtitles": subtitles.map((e) => e.toMap()).toList(),
    "payload": payload,
  };
}

class QualityItem {
  String name;
  String link;
  Map<String, String>? headers;
  bool use_proxy = false;

  QualityItem({
    required this.name,
    required this.link,
    this.headers,
    this.use_proxy = false,
  });

  factory QualityItem.fromMap(Map<String, dynamic> map) => QualityItem(
    name: map["name"] ?? "",
    link: map["link"] ?? "",
    headers: MapUtilities.convert<String, String>(map["headers"]),
    use_proxy: map["use_proxy"] ?? false,
  );

  Map<String, dynamic> toMap() => {
    "name": name,
    "link": link,
    "headers": headers,
    "use_proxy": use_proxy,
  };
}

class SubtitleItemKey {
  String nameKey;
  String linkKey;
  String seasonKey;
  String episodeKey;
  String formatKey;
  SubtitleFetchExtension extension = SubtitleFetchExtension.text;

  SubtitleItemKey({
    required this.nameKey,
    required this.linkKey,
    required this.seasonKey,
    required this.episodeKey,
    required this.formatKey,
    this.extension = SubtitleFetchExtension.text,
  });

  factory SubtitleItemKey.fromMap(Map<String, dynamic> map) {
    return SubtitleItemKey(
      nameKey: map["name"] ?? "SubFileName",
      linkKey: map["link"] ?? "SubDownloadLink",
      seasonKey: map["season"] ?? "SeriesSeason",
      episodeKey: map["episode"] ?? "SeriesEpisode",
      formatKey: map["format"] ?? "SubFormat",
      extension:
          SubtitleFetchExtension.values.firstWhereOrNull(
            (e) => e.name.toLowerCase() == (map["extension"] ?? "text"),
          ) ??
          SubtitleFetchExtension.text,
    );
  }

  Map<String, dynamic> toMap() => {
    "name": nameKey,
    "link": linkKey,
    "season": seasonKey,
    "episode": episodeKey,
    "extension": extension.name,
    "format": formatKey,
  };
}

class SubtitleItem {
  String name;
  String link;
  String? real_link;
  Map<String, String>? headers;
  SubtitleRootType type;
  SubtitleItemKey? key;

  List<Map<String, dynamic>> children;

  SubtitleItem({
    required this.name,
    required this.link,
    required this.type,
    this.key,
    this.real_link,
    this.headers,
    this.children = const [],
  });

  factory SubtitleItem.fromMap(Map<String, dynamic> map) => SubtitleItem(
    name: map["name"] ?? "",
    link: map["link"] ?? "",
    real_link: map["dlLink"] ?? "",
    key: map["key"] != null ? SubtitleItemKey.fromMap(map["key"]) : null,
    type:
        SubtitleRootType.values.firstWhereOrNull(
          (e) => e.name.toLowerCase() == (map["type"] ?? "normal"),
        ) ??
        SubtitleRootType.normal,
    headers: MapUtilities.convert<String, String>(map["headers"]),
    children: List<Map<String, dynamic>>.from(map["children"] ?? []),
  );

  Map<String, dynamic> toMap() => {
    "name": name,
    "link": link,
    "type": type.name,
    "dlLink": real_link,
    "headers": headers,
    "key": key?.toMap(),
    "children": children,
  };

  @override
  int get hashCode => link.hashCode ^ real_link.hashCode;

  @override
  bool operator ==(Object other) {
    return other is SubtitleItem &&
        other.link == link &&
        other.real_link == real_link;
  }
}
