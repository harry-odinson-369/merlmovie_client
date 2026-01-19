import 'dart:collection';
import 'dart:ui';
import 'dart:io';

import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/extensions/uri.dart';
import 'package:merlmovie_client/src/helpers/color.dart';
import 'package:merlmovie_client/src/helpers/map.dart';

enum PluginSource { file, server, create }

enum StreamType { webview, api }

enum RequestSelectType { single, multi }

enum PluginVisibility { all, ios, android, none, development }

enum MediaType { multi, tv, movie }

enum PluginOpenType { player, webview }

enum PluginImageSize { normal, cover }

class PluginModel {
  String id;
  PluginOpenType openType = PluginOpenType.player;
  Color? logoBackgroundColor;
  StreamType streamType = StreamType.api;
  MediaType mediaType = MediaType.multi;
  String embedUrl = "";
  String tvEmbedUrl = "";
  Map<String, String>? headers;
  String name = "";
  String image = "";
  String author = "Anonymous";
  String description = "";
  String script = "";
  int initialScriptMs = 1000;
  String officialWebsite = "";
  bool useIMDb = false;
  PluginVisibility visible = PluginVisibility.all;
  String version = "1.0.0";
  List<String> query = [];
  PluginSource installedSource = PluginSource.server;
  String? updatableUrl;
  PluginImageSize imageSize = PluginImageSize.normal;

  /// Used to indicate the plugin is required user to select item while loading source.
  RequestSelectType requestSelectType = RequestSelectType.single;

  /// Allow the domain name are in this array only.
  List<String> allowedDomains = [];

  bool get underDevelopment => visible == PluginVisibility.development;

  bool get useWebView => streamType == StreamType.webview;

  bool get useInternalPlayer => streamType == StreamType.api;

  ///This property is indicate this plugin can show up on plugins page to be installable.
  bool get isCanVisible {
    var platform =
        Platform.isIOS ? PluginVisibility.ios : PluginVisibility.android;
    bool isTrue =
        visible == PluginVisibility.all ||
        visible == PluginVisibility.development;
    return isTrue || visible == platform;
  }

  PluginModel({
    this.id = "",
    this.openType = PluginOpenType.player,
    this.streamType = StreamType.api,
    this.mediaType = MediaType.multi,
    this.visible = PluginVisibility.all,
    this.installedSource = PluginSource.server,
    this.embedUrl = "",
    this.tvEmbedUrl = "",
    this.headers,
    this.name = "",
    this.description = "",
    this.image = "",
    this.script = "",
    this.officialWebsite = "",
    this.useIMDb = false,
    this.logoBackgroundColor,
    this.allowedDomains = const [],
    this.author = "Anonymous",
    this.version = "1.0.0",
    this.query = const [],
    this.requestSelectType = RequestSelectType.single,
    this.updatableUrl,
    this.imageSize = PluginImageSize.normal,
    this.initialScriptMs = 1000,
  });

  String get website {
    if (officialWebsite.isNotEmpty) {
      return officialWebsite;
    } else {
      var uri = Uri.parse(embedUrl);
      return "https://${uri.host}";
    }
  }

  factory PluginModel.fromMap(Map<String, dynamic> map) {
    List<String> allowedDomains0 = List<String>.from(
      (map["allowed_domains"] ?? []),
    );

    String? url = map["embed_url"];
    String? tvUrl = map["tv_embed_url"];

    if (url != null) {
      final uri = Uri.parse(url);
      allowedDomains0.add(uri.hostname_only);
    }

    if (tvUrl != null) {
      final uri = Uri.parse(tvUrl);
      allowedDomains0.add(uri.hostname_only);
    }

    allowedDomains0 = LinkedHashSet<String>.from(allowedDomains0).toList();
    allowedDomains0.removeWhere((e) => e == "" || e == " " || e.isEmpty);

    var bgColor = ColorUtilities.fromHex(map["logo_background_color"]);

    return PluginModel(
      id: map["id"] ?? "",
      embedUrl: url ?? "",
      tvEmbedUrl: tvUrl ?? "",
      headers: MapUtilities.convert<String, String>(map["headers"]),
      name: map["name"] ?? "",
      image: map["image"] ?? "",
      description: map["description"] ?? "",
      script: map["script"] ?? "",
      officialWebsite: map["official_website"] ?? "",
      useIMDb: map["use_imdb"] ?? false,
      logoBackgroundColor: bgColor,
      author: map["author"] ?? "Anonymous",
      version: map["version"] ?? "1.0.0",
      allowedDomains: allowedDomains0,
      query: List<String>.from(map["query"] ?? []),
      visible: PluginVisibility.values.findEnum(
        map["visible"],
        PluginVisibility.all,
      ),
      installedSource: PluginSource.values.findEnum(
        map["installed_source"],
        PluginSource.server,
      ),
      openType: PluginOpenType.values.findEnum(
        map["open_type"],
        PluginOpenType.player,
      ),
      streamType: StreamType.values.findEnum(
        map["stream_type"],
        StreamType.api,
      ),
      requestSelectType: RequestSelectType.values.findEnum(
        map["request_select_type"],
        RequestSelectType.single,
      ),
      mediaType: MediaType.values.findEnum(map["media_type"], MediaType.multi),
      imageSize: PluginImageSize.values.findEnum(
        map["image_size"],
        PluginImageSize.normal,
      ),
      updatableUrl: map["updatable_url"],
      initialScriptMs: int.parse('${map["initial_script_ms"] ?? 1000}'),
    );
  }

  String get logoBgToHex {
    if (logoBackgroundColor != null) {
      String hex = ColorUtilities.toHex(logoBackgroundColor!);
      return ColorUtilities.resolveHex(hex);
    } else {
      return "";
    }
  }

  Map<String, dynamic> toMap() => {
    "id": id,
    "open_type": openType.name,
    "stream_type": streamType.name,
    "media_type": mediaType.name,
    "embed_url": embedUrl,
    "tv_embed_url": tvEmbedUrl,
    "headers": headers,
    "name": name,
    "image": image,
    "description": description,
    "script": script,
    "official_website": officialWebsite,
    "use_imdb": useIMDb,
    "visible": visible.name,
    "logo_background_color": logoBackgroundColor != null ? logoBgToHex : null,
    "author": author,
    "version": version,
    "allowed_domains": allowedDomains,
    "query": query,
    "installed_source": installedSource.name,
    "request_select_type": requestSelectType.name,
    "updatable_url": updatableUrl,
    "image_size": imageSize.name,
    "initial_script_ms": initialScriptMs,
  };

  void update(PluginModel p) {
    openType = p.openType;
    streamType = p.streamType;
    mediaType = p.mediaType;
    visible = p.visible;
    installedSource = p.installedSource;

    embedUrl = p.embedUrl;
    tvEmbedUrl = p.tvEmbedUrl;
    headers = p.headers;

    name = p.name;
    image = p.image;
    description = p.description;
    script = p.script;
    officialWebsite = p.officialWebsite;

    useIMDb = p.useIMDb;
    logoBackgroundColor = p.logoBackgroundColor;
    author = p.author;
    version = p.version;

    allowedDomains = p.allowedDomains;
    query = p.query;

    requestSelectType = p.requestSelectType;
    updatableUrl = p.updatableUrl;
    imageSize = p.imageSize;
  }

  bool _compare_arr(List a, List b) {
    if (a.isEmpty && b.isEmpty) return true;
    return a.every((item) => b.contains(item));
  }

  bool compare(PluginModel other) {
    return streamType == other.streamType &&
        mediaType == other.mediaType &&
        visible == other.visible &&
        _compare_arr(allowedDomains, other.allowedDomains) &&
        openType == other.openType &&
        useIMDb == other.useIMDb &&
        script == other.script;
  }

  @override
  bool operator ==(Object other) {
    return other is PluginModel && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
