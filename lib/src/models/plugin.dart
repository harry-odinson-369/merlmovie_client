import 'dart:collection';
import 'dart:ui';
import 'dart:io';

import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/extensions/uri.dart';
import 'package:merlmovie_client/src/helpers/color.dart';
import 'package:merlmovie_client/src/helpers/map.dart';

enum PluginSource { file, server, create }

enum StreamType { webview, iframe, api, internal }

enum PluginVisibility { all, ios, android, none, development }

enum MediaType { multi, tv, movie }

enum WebViewProviderType { webview_flutter, flutter_inappwebview }

enum PluginOpenType { player, webview }

class PluginModel {
  PluginOpenType openType = PluginOpenType.player;
  Color? logoBackgroundColor;
  StreamType streamType = StreamType.internal;
  MediaType mediaType = MediaType.multi;
  String embedUrl = "";
  String tvEmbedUrl = "";
  Map<String, String>? headers;
  String name = "";
  String image = "";
  String author = "Anonymous";
  String description = "";
  String script = "";
  String officialWebsite = "";
  bool useIMDb = false;
  PluginVisibility visible = PluginVisibility.all;
  String? docId;
  String version = "1.0.0";
  WebViewProviderType webView = WebViewProviderType.flutter_inappwebview;
  List<String> query = [];
  PluginSource installedSource = PluginSource.server;

  ///[allowedDomains] is only work when [webView] set to [WebViewProviderType.webview_flutter]
  List<String> allowedDomains = [];

  bool get underDevelopment => visible == PluginVisibility.development;

  bool get useWebView =>
      streamType == StreamType.iframe || streamType == StreamType.webview;

  bool get useInternalPlayer =>
      streamType == StreamType.api || streamType == StreamType.internal;

  bool get useIframe => streamType == StreamType.iframe;

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
    this.openType = PluginOpenType.player,
    this.streamType = StreamType.internal,
    this.mediaType = MediaType.multi,
    this.embedUrl = "",
    this.tvEmbedUrl = "",
    this.headers,
    this.name = "",
    this.description = "",
    this.image = "",
    this.script = "",
    this.officialWebsite = "",
    this.useIMDb = false,
    this.visible = PluginVisibility.all,
    this.docId,
    this.logoBackgroundColor,
    this.webView = WebViewProviderType.flutter_inappwebview,
    this.allowedDomains = const [],
    this.author = "Anonymous",
    this.version = "1.0.0",
    this.query = const [],
    this.installedSource = PluginSource.server,
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
      allowedDomains0.add(uri.domainNameOnly);
    }

    if (tvUrl != null) {
      final uri = Uri.parse(tvUrl);
      allowedDomains0.add(uri.domainNameOnly);
    }

    allowedDomains0 = LinkedHashSet<String>.from(allowedDomains0).toList();
    allowedDomains0.removeWhere((e) => e == "" || e == " " || e.isEmpty);

    return PluginModel(
      openType: PluginOpenType.values.firstWhere(
        (e) => e.name == (map["open_type"] ?? PluginOpenType.player.name),
      ),
      streamType: StreamType.values.firstWhere(
        (e) => e.name == (map["stream_type"] ?? StreamType.internal.name),
      ),
      mediaType: MediaType.values.firstWhere(
        (e) => e.name == (map["media_type"] ?? "multi"),
      ),
      embedUrl: url ?? "",
      tvEmbedUrl: tvUrl ?? "",
      headers: MapUtilities.convert<String, String>(map["headers"]),
      name: map["name"] ?? "",
      image: map["image"] ?? "",
      description: map["description"] ?? "",
      script: map["script"] ?? "",
      officialWebsite: map["official_website"] ?? "",
      useIMDb: map["use_imdb"] ?? false,
      visible:
          PluginVisibility.values.firstWhereOrNull(
            (e) => e.name == map["visible"],
          ) ??
          PluginVisibility.all,
      docId: map["_docId"],
      logoBackgroundColor:
          map["logo_background_color"] != null
              ? ColorUtilities.fromHex(map["logo_background_color"])
              : null,
      author: map["author"] ?? "Anonymous",
      version: map["version"] ?? "1.0.0",
      webView:
          WebViewProviderType.values.firstWhereOrNull((e) {
            return (map["webview_type"] ??
                    WebViewProviderType.flutter_inappwebview.name) ==
                e.name;
          }) ??
          WebViewProviderType.flutter_inappwebview,
      allowedDomains: allowedDomains0,
      query: List<String>.from(map["query"] ?? []),
      installedSource:
          PluginSource.values.firstWhereOrNull((e) {
            return e.name == (map["installed_source"] ?? "server");
          }) ??
          PluginSource.server,
    );
  }

  String get logoBgToHex {
    if (logoBackgroundColor != null) {
      String hex = ColorUtilities.toHex(logoBackgroundColor!);
      if (hex.length == 9 && hex.endsWith("ff")) {
        return hex.substring(0, hex.length - 2);
      } else if (hex.length == 8 && hex.endsWith("ff")) {
        return hex.substring(0, hex.length - 2);
      } else {
        return hex;
      }
    } else {
      return "";
    }
  }

  Map<String, dynamic> toMap() => {
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
    "_docId": docId,
    "logo_background_color": logoBackgroundColor != null ? logoBgToHex : null,
    "author": author,
    "version": version,
    "webview_type": webView.name,
    "allowed_domains": allowedDomains,
    "query": query,
    "installed_source": installedSource.name,
  };

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
        script == other.script &&
        webView == other.webView;
  }

  @override
  bool operator ==(Object other) {
    return other is PluginModel &&
        name == other.name &&
        embedUrl == other.embedUrl &&
        tvEmbedUrl == other.tvEmbedUrl;
  }

  @override
  int get hashCode => name.hashCode ^ embedUrl.hashCode ^ tvEmbedUrl.hashCode;
}
