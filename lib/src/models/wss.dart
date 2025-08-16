import 'dart:convert';

import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/helpers/map.dart';

enum WSSAction {
  stream,
  fetch,
  result,
  progress,
  failed,
  browser,
  browser_result,
  browser_close,
  browser_click,
  browser_url_request,
  browser_url_finished,
  browser_evaluate,
  browser_evaluate_result,
  browser_cookie,
  browser_cookie_result,
  browser_set_cookie,
  browser_visible,
  select,
  select_result,
}

class WSSDataModel {
  WSSAction action;
  String? id;
  Map<String, dynamic> data;

  WSSDataModel({required this.action, required this.data, this.id});

  factory WSSDataModel.fromMap(Map<String, dynamic> map) => WSSDataModel(
    action: WSSAction.values.firstWhere(
      (e) => e.name == (map["action"] ?? "stream"),
    ),
    id: map["__id"],
    data: convertData(map["data"]),
  );

  Map<String, dynamic> toMap() => {
    "action": action.name,
    "data": data,
    "__id": id,
  };

  static Map<String, dynamic> convertData(dynamic d) {
    if (d is String) {
      return json.decode(d);
    } else if (d is Map) {
      return MapUtilities.convert<String, dynamic>(d) ?? {};
    } else {
      return MapUtilities.convert<String, dynamic>({}) ?? {};
    }
  }

  WSSHttpDataModel get httpInfo => WSSHttpDataModel.fromMap(data);

  WSSBrowserWebDataModel get browserInfo =>
      WSSBrowserWebDataModel.fromMap({...data, "__id": id});

  BrowserWebVisible get visible =>
      BrowserWebVisible.values.firstWhereOrNull(
        (e) => e.name == data["show"].toString().toLowerCase(),
      ) ??
      BrowserWebVisible.no;
}

enum BrowserWebType { web_0, web_1 }

enum BrowserWebVisible { no, yes }

enum WSSSelectImageType { poster, banner }

class WSSSelectModel {
  String title, image, subtitle;
  WSSSelectImageType imageType = WSSSelectImageType.poster;
  Map<String, dynamic> data;

  WSSSelectModel({
    this.title = "",
    this.subtitle = "",
    this.image = "",
    this.data = const {},
    this.imageType = WSSSelectImageType.poster,
  });

  factory WSSSelectModel.fromMap(Map<String, dynamic> map) => WSSSelectModel(
    title: map["title"] ?? "",
    subtitle: map["subtitle"] ?? "",
    image: map["image"] ?? "",
    imageType: WSSSelectImageType.values.findEnum(
      map["image_type"],
      WSSSelectImageType.poster,
    ),
    data: MapUtilities.convert<String, dynamic>(map["data"]) ?? {},
  );

  Map<String, dynamic> toMap() => {
    "title": title,
    "subtitle": subtitle,
    "image": image,
    "image_type": imageType.name,
    "data": data,
  };
}

class WSSBrowserWebDataModel {
  BrowserWebType type = BrowserWebType.web_0;
  String url;
  Map<String, String>? headers;
  BrowserWebVisible visible = BrowserWebVisible.no;
  String? id;

  WSSBrowserWebDataModel({
    required this.url,
    this.type = BrowserWebType.web_0,
    this.headers,
    this.visible = BrowserWebVisible.no,
    this.id,
  });

  factory WSSBrowserWebDataModel.fromMap(
    Map<String, dynamic> map,
  ) => WSSBrowserWebDataModel(
    url: map["url"] ?? "",
    headers: MapUtilities.convert<String, String>(map["headers"]),
    type:
        BrowserWebType.values.firstWhereOrNull(
          (e) => e.name.toLowerCase() == map["type"].toString().toLowerCase(),
        ) ??
        BrowserWebType.web_0,
    visible:
        BrowserWebVisible.values.firstWhereOrNull(
          (e) =>
              e.name.toLowerCase() == map["visible"].toString().toLowerCase(),
        ) ??
        BrowserWebVisible.no,
    id: map["__id"],
  );

  Map<String, dynamic> toMap() => {
    "url": url,
    "headers": headers,
    "type": type.name,
    "visible": visible.name,
    "__id": id,
  };
}

enum WSSHttpFetchResponseType { dynamic, bytes }

enum WSSHttpDbMethod { get, set, delete }

enum WSSFetchApiType { http, axios }

class AxiosModel {
  String? cdn;
  String? script;

  AxiosModel({this.cdn, this.script});

  factory AxiosModel.fromMap(Map<String, dynamic> map) =>
      AxiosModel(cdn: map["cdn"], script: map["script"]);

  Map<String, dynamic> toMap() => {"cdn": cdn, "script": script};
}

class WSSHttpDataModel {
  String method;
  String url;
  Map<String, String>? headers;
  Object? body;
  WSSHttpFetchResponseType responseType;
  int timeout = 60;
  WSSFetchApiType api = WSSFetchApiType.http;
  AxiosModel axios;

  WSSHttpDataModel({
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
    required this.responseType,
    required this.timeout,
    required this.api,
    required this.axios,
  });

  bool get isResponseBytes => responseType == WSSHttpFetchResponseType.bytes;

  WSSHttpDbMethod get dbMethod {
    final split = url.replaceAll("db://", "").split(":");
    return WSSHttpDbMethod.values.firstWhereOrNull((e) => e.name == split[0]) ??
        WSSHttpDbMethod.get;
  }

  String get dbKey {
    final split = url.replaceAll("db://", "").split(":");
    return split[1];
  }

  factory WSSHttpDataModel.fromMap(Map<String, dynamic> map) =>
      WSSHttpDataModel(
        method: map["method"] ?? "get",
        url: map["url"] ?? "",
        headers: MapUtilities.convert<String, String>(map["headers"]),
        body: map["body"],
        responseType: WSSHttpFetchResponseType.values.firstWhere(
          (e) =>
              e.name ==
              (map["response_type"] ?? "dynamic").toString().toLowerCase(),
        ),
        timeout: map["timeout"] ?? 60,
        api:
            WSSFetchApiType.values.firstWhereOrNull(
              (e) =>
                  (e.name.toLowerCase() ==
                      (map["api"]).toString().toLowerCase()),
            ) ??
            WSSFetchApiType.http,
        axios: AxiosModel.fromMap(map["axios"] ?? {}),
      );

  Map<String, dynamic> toMap() => {
    "method": method,
    "url": url,
    "headers": headers,
    "body": body,
    "response_type": responseType.name,
    "timeout": timeout,
    "api": api.name,
    "axios": axios.toMap(),
  };
}
