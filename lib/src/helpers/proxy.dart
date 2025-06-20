import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/helpers/map.dart';
import 'package:merlmovie_client/src/helpers/themoviedb.dart';
import 'package:merlmovie_client/src/models/movie.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

String _hostname = "127.0.0.1";
int _port = 3696;

class MerlMovieHttpProxyService {
  static int get port => _port;
  static set port(int p) {
    _port = p;
  }

  static String get hostname => _hostname;
  static set hostname(String h) {
    _hostname = h;
  }

  static String get _SEGMENT_KEY => "is-hls-seg=true";

  static String base([String? path]) {
    return "http://$hostname:$port/${path ?? ""}";
  }

  static Future<http.Response> _timeout(Future<http.Response> request) async {
    try {
      return await request.timeout(
        const Duration(seconds: 12),
        onTimeout: () async => http.Response("Connection timeout!", 408),
      );
    } catch (err) {
      log("[Http Proxy Service] ${err.toString()}");
      return http.Response("Unexpected error!", 500);
    }
  }

  static Future<bool> get isServing async {
    final response = await _timeout(http.get(Uri.parse(base("status"))));
    return response.statusCode == 200;
  }

  static String create_proxy_url(
    String destination, [
    Map<String, String>? headers,
  ]) {
    return base(
      "?d=${Uri.encodeComponent(destination)}${headers != null ? "&h=${Uri.encodeComponent(json.encode(headers).replaceAll("\n", ""))}" : ""}",
    );
  }

  static Future<HttpServer> serve() =>
      io.serve(_intercept_handler, hostname, port);

  static Future<Isolate> background_serve([int? PORT, String? HOSTNAME]) async {
    return Isolate.spawn<Map<String, dynamic>>(_background_serve, {
      "port": PORT ?? port,
      "hostname": HOSTNAME ?? hostname,
    });
  }

  static void _background_serve(Map<String, dynamic> args) async {
    try {
      io.serve(_intercept_handler, args["hostname"], args["port"]);
    } catch (err) {
      io.serve(_intercept_handler, args["hostname"], args["port"]);
    }
  }

  static Future<shelf.Response> _intercept_handler(
    shelf.Request request,
  ) async {
    log("[Http Proxy Service] Incoming Request: ${request.url.toString()}");
    final res = await _handler(request);
    log("[Http Proxy Service] Response: ${res.statusCode}");
    return res;
  }

  static Future<shelf.Response> _handler(shelf.Request request) async {
    if (request.url.pathSegments.isNotEmpty &&
        request.url.pathSegments.first == "status") {
      return shelf.Response.ok("Serving...");
    }

    if (request.url.pathSegments.isNotEmpty &&
        request.url.pathSegments.first == "title-logo") {
      return _handle_title_logo(request);
    }

    String? destination = _restore_destination(
      request.url.queryParameters["d"],
    );
    Map<String, String>? headers = _restore_headers(
      request.url.queryParameters["h"],
    );

    if (destination == null) {
      return shelf.Response.badRequest();
    }

    Map<String, String> desired_headers = {
      ..._get_necessary_headers(request.headers),
      ...(headers ?? {}),
    };

    if (await _isHls(destination, headers)) {
      return _handle_hls(destination, desired_headers);
    } else {
      return _handle_dynamic(destination, desired_headers);
    }
  }

  static Map<String, String> _get_necessary_headers(
    Map<String, String> headers,
  ) {
    final range = headers[HttpHeaders.rangeHeader];
    return range != null ? {HttpHeaders.rangeHeader: range} : {};
  }

  static Future<shelf.Response> _handle_title_logo(
    shelf.Request request,
  ) async {
    try {
      final params = request.url.queryParameters;
      String? media_id = params["media_id"];
      String? media_type = params["media_type"];
      TMDBImageSize? size = TMDBImageSize.values.firstWhereOrNull(
        (e) => e.name == params["size"],
      );
      String? api_key = params["api_key"];

      String request_url = TheMovieDbApi.v3(
        "$media_type/$media_id?api_key=$api_key&append_to_response=images",
      );

      final resp = await http.get(Uri.parse(request_url));

      if (resp.statusCode == HttpStatus.ok) {
        final detail = DetailModel.fromMap(json.decode(resp.body));
        if (detail.real_title_logo.isNotEmpty) {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          final io_client = IOClient(client);
          final request = http.Request(
            "GET",
            Uri.parse(
              TheMovieDbApi.getImage(
                detail.real_title_logo,
                size ?? TMDBImageSize.w500,
              ),
            ),
          )..followRedirects = false;
          final streamed_response = await io_client.send(request);
          final headers = Map<String, String>.from(streamed_response.headers);
          return shelf.Response(
            streamed_response.statusCode,
            body: streamed_response.stream,
            headers: headers,
          );
        }
        return shelf.Response.notFound("");
      }

      return shelf.Response.notFound("");
    } catch (err) {
      log("[Http Proxy Service] Error title_logo: ${err.toString()}");
      return shelf.Response.internalServerError();
    }
  }

  static Future<shelf.Response> _handle_hls(
    String destination, [
    Map<String, String>? headers,
  ]) async {
    try {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      final io_client = IOClient(client);
      final request =
          http.Request("GET", Uri.parse(destination))
            ..followRedirects = false
            ..headers.addAll(headers ?? {});
      final streamed_response = await io_client.send(request);
      final response = await http.Response.fromStream(streamed_response);
      if (response.body.trimLeft().startsWith(
        HlsPlaylistParser.PLAYLIST_HEADER,
      )) {
        final parsed = await HlsPlaylistParser.create().parseString(
          // Avoid auto add relative url.
          Uri.parse(""),
          response.body,
        );
        String modified = _rewrite_hls(
          destination,
          response.body,
          parsed,
          headers,
        );
        return shelf.Response.ok(
          modified,
          headers: {
            HttpHeaders.contentTypeHeader: "application/vnd.apple.mpegurl",
          },
        );
      }
      return shelf.Response(
        response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    } catch (err) {
      return shelf.Response.internalServerError();
    }
  }

  static String _rewrite_hls(
    String destination,
    String content,
    dynamic parsed,
    Map<String, String>? headers,
  ) {
    if (parsed is HlsMasterPlaylist) {
      return _rewrite_hls_master(destination, content, parsed, headers);
    } else if (parsed is HlsMediaPlaylist) {
      return _rewrite_hls_playlist(destination, content, parsed, headers);
    }
    return "Unknown hls type!";
  }

  static String _rewrite_hls_master(
    String destination,
    String content,
    HlsMasterPlaylist master,
    Map<String, String>? headers,
  ) {
    String newContent = content;
    for (final variant in master.variants) {
      bool resolvable = !variant.url.toString().startsWith("http");
      String resolved_url =
          resolvable
              ? Uri.parse(destination).resolveUri(variant.url).toString()
              : variant.url.toString();
      String d = Uri.encodeComponent(resolved_url);
      String? h;
      if (headers != null) {
        h = Uri.encodeComponent(json.encode(headers).replaceAll("\n", ""));
      }
      String newUrl = base("?d=$d${h != null ? "&h=$h" : ""}");
      newContent = newContent.replaceAll(variant.url.toString(), newUrl);
    }
    return newContent;
  }

  static String _rewrite_hls_playlist(
    String destination,
    String content,
    HlsMediaPlaylist media,
    Map<String, String>? headers,
  ) {
    String newContent = content;
    for (final segment in media.segments) {
      if (segment.url != null) {
        bool resolvable = !segment.url.toString().startsWith("http");
        String resolved_url =
            resolvable
                ? Uri.parse(
                  destination,
                ).resolve(segment.url.toString()).toString()
                : segment.url.toString();
        String d = Uri.encodeComponent(resolved_url);
        String? h;
        if (headers != null) {
          h = Uri.encodeComponent(json.encode(headers).replaceAll("\n", ""));
        }
        String newUrl = base("?$_SEGMENT_KEY&d=$d${h != null ? "&h=$h" : ""}");
        newContent = newContent.replaceAll(segment.url.toString(), newUrl);
      }
    }
    return newContent;
  }

  static Future<shelf.Response> _handle_dynamic(
    String destination, [
    Map<String, String>? headers,
  ]) async {
    try {
      final uri = Uri.parse(destination);
      final request = http.Request("GET", uri);
      request.headers.addAll(headers ?? {});
      final streamedResponse = await request.send();
      final responseHeaders = Map<String, String>.from(
        streamedResponse.headers,
      );
      if (destination.contains(_SEGMENT_KEY)) {
        responseHeaders[HttpHeaders.contentTypeHeader] = "video/mp2t";
      }
      return shelf.Response(
        streamedResponse.statusCode,
        body: streamedResponse.stream,
        headers: responseHeaders,
      );
    } catch (err) {
      log("[Http Proxy Service]: $err");
      return shelf.Response.internalServerError(
        body: "Failed to fetch resource.",
      );
    }
  }

  static Map<String, String>? _restore_headers(String? encoded_headers) {
    if (encoded_headers == null) return null;
    try {
      String decoded = Uri.decodeComponent(encoded_headers);
      return MapUtilities.convert<String, String>(json.decode(decoded));
    } catch (err) {
      log("[Http Proxy Service] Error: ${err.toString()}");
      return null;
    }
  }

  static String? _restore_destination(String? destination) {
    if (destination == null) return null;
    return Uri.decodeComponent(destination);
  }

  static Future<bool> _isHls(
    String destination, [
    Map<String, String>? headers,
  ]) async {
    if (destination.contains(_SEGMENT_KEY)) return false;
    try {
      final request =
          http.Request("GET", Uri.parse(destination))
            ..followRedirects = false
            ..headers.addAll(headers ?? {});
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      final io_client = IOClient(client);
      final response = await io_client.send(request);
      final body = await utf8.decodeStream(response.stream.take(1));
      return body.trimLeft().startsWith(HlsPlaylistParser.PLAYLIST_HEADER);
    } catch (_) {
      return false;
    }
  }
}
