import 'dart:convert';

import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/helpers/map.dart';

enum DirectLinkDataStatus { PROGRESS_STATUS, FINAL_RESULT }

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

  QualityItem({required this.name, required this.link, this.headers});

  factory QualityItem.fromMap(Map<String, dynamic> map) => QualityItem(
    name: map["name"] ?? "",
    link: map["link"] ?? "",
    headers: MapUtilities.convert<String, String>(map["headers"]),
  );

  Map<String, dynamic> toMap() => {
    "name": name,
    "link": link,
    "headers": headers,
  };
}

class SubtitleItemKey {
  String nameKey;
  String linkKey;
  SubtitleFetchExtension extension = SubtitleFetchExtension.text;

  SubtitleItemKey({
    required this.nameKey,
    required this.linkKey,
    this.extension = SubtitleFetchExtension.text,
  });

  factory SubtitleItemKey.fromMap(Map<String, dynamic> map) {
    return SubtitleItemKey(
      nameKey: map["name"] ?? "",
      linkKey: map["link"] ?? "",
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
    "extension": extension.name,
  };
}

class SubtitleItem {
  String name;
  String link;
  String? dlLink;
  Map<String, String>? headers;
  SubtitleRootType type;
  SubtitleItemKey? key;

  SubtitleItem({
    required this.name,
    required this.link,
    required this.type,
    this.key,
    this.dlLink,
    this.headers,
  });

  factory SubtitleItem.fromMap(Map<String, dynamic> map) => SubtitleItem(
    name: map["name"] ?? "",
    link: map["link"] ?? "",
    dlLink: map["dlLink"] ?? "",
    key: map["key"] != null ? SubtitleItemKey.fromMap(map["key"]) : null,
    type:
        SubtitleRootType.values.firstWhereOrNull(
          (e) => e.name.toLowerCase() == (map["type"] ?? "normal"),
        ) ??
        SubtitleRootType.normal,
    headers: MapUtilities.convert<String, String>(map["headers"]),
  );

  Map<String, dynamic> toMap() => {
    "name": name,
    "link": link,
    "type": type.name,
    "dlLink": dlLink,
    "headers": headers,
    "key": key?.toMap(),
  };
}
