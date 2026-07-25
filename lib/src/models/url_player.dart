import 'package:merlmovie_client/src/models/plugin.dart';

class URLPlayerModel {
  String name;
  String url;
  /// [allowed_hosts] work differently from [PluginModel.allowedDomains]. [allowed_hosts] should be like 'example.com'.
  List<String> allowed_hosts;
  Map<String, String> headers = <String, String>{};
  String? script;
  int executeScriptMs = 1000;

  URLPlayerModel({
    this.name = "",
    this.url = "",
    this.allowed_hosts = const [],
    this.headers = const <String, String>{},
    this.script,
    this.executeScriptMs = 1000,
  });

  factory URLPlayerModel.fromMap(Map<String, dynamic> map) => URLPlayerModel(
    name: map['name'] ?? "",
    url: map['url'] ?? "",
    allowed_hosts: List<String>.from((map['allowed_hosts'] ?? [])),
    headers: Map<String, String>.from(map['headers'] ?? {}),
    script: map['script'],
    executeScriptMs: map['execute_script_ms'] ?? 1000,
  );

  Map<String, dynamic> toMap() => {
    "name": name,
    "url": url,
    "allowed_hosts": allowed_hosts,
    "headers": headers,
    "script": script,
    "execute_script_ms": executeScriptMs,
  };
}
