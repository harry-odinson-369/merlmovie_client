import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:subtitle/subtitle.dart';

class SubtitleHelper {
  static Future<String> extractGz(
    String link, [
    Map<String, String>? headers,
  ]) async {
    final response = await http.get(Uri.parse(link), headers: headers);
    final archive = GZipDecoder().decodeBytes(response.bodyBytes);
    return utf8.decode(archive);
  }

  static Future<String> extractZip(
    String link, [
    Map<String, String>? headers,
  ]) async {
    final response = await http.get(Uri.parse(link), headers: headers);
    final archive = ZipDecoder().decodeBytes(response.bodyBytes);
    for (final f in archive.files) {
      try {
        final content = utf8.decode(f.content);
        final format = SubtitleHelper.detectFormat(content);
        if (format == SubtitleType.vtt || format == SubtitleType.srt) {
          return content;
        }
      } catch (err) {
        debugPrint(err.toString());
      }
    }
    return "";
  }

  static Future<List<Subtitle>> fromNetwork(
    Uri uri, {
    Map<String, String>? headers,
    SubtitleFetchExtension extension = SubtitleFetchExtension.text,
  }) async {
    try {
      if (extension == SubtitleFetchExtension.text) {
        final response = await http.get(uri, headers: headers);
        try {
          String content = response.body;
          final format = SubtitleHelper.detectFormat(content);
          if (format == SubtitleType.srt || format == SubtitleType.vtt) {
            content = SubtitleHelper.cleanSubtitles(content);
            var controller = SubtitleController(
              provider: SubtitleProvider.fromString(
                data: content,
                type: format,
              ),
            );
            await controller.initial();
            return controller.subtitles;
          } else {
            return [];
          }
        } catch (err) {
          debugPrint(err.toString());
          return [];
        }
      } else if (extension == SubtitleFetchExtension.gz) {
        String content = await extractGz(uri.toString(), headers);
        content = SubtitleHelper.cleanSubtitles(content);
        var controller = SubtitleController(
          provider: SubtitleProvider.fromString(
            data: content,
            type: SubtitleHelper.detectFormat(content),
          ),
        );
        await controller.initial();
        return controller.subtitles;
      } else if (extension == SubtitleFetchExtension.zip) {
        String content = await extractZip(uri.toString(), headers);
        content = SubtitleHelper.cleanSubtitles(content);
        var controller = SubtitleController(
          provider: SubtitleProvider.fromString(
            data: content,
            type: SubtitleHelper.detectFormat(content),
          ),
        );
        await controller.initial();
        return controller.subtitles;
      } else {
        return [];
      }
    } catch (error) {
      debugPrint("Error while getting subtitle from network: $error");
      return [];
    }
  }

  static Future<List<Subtitle>> fromFile(String path) async {
    try {
      var content = await File(path).readAsString();
      content = SubtitleHelper.cleanSubtitles(content);
      var type = detectFormat(content);
      var controller = SubtitleController(
        provider: SubtitleProvider.fromString(data: content, type: type),
      );
      await controller.initial();
      return controller.subtitles;
    } catch (error) {
      debugPrint("Error while getting subtitle from file: $error");
      return [];
    }
  }

  static SubtitleType detectFormat(String content) {
    if (content.trimLeft().startsWith('WEBVTT')) return SubtitleType.vtt;
    final srtTimestampRegex = RegExp(
      r'\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}',
    );
    final vttTimestampRegex = RegExp(
      r'\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}',
    );
    if (vttTimestampRegex.hasMatch(content)) return SubtitleType.vtt;
    if (srtTimestampRegex.hasMatch(content)) return SubtitleType.srt;
    return SubtitleType.custom;
  }

  static String cleanSubtitles(String content) {
    final regExp = RegExp(
      r'<[^>]*>|{\s*\\an\d+}',
      multiLine: true,
      caseSensitive: false,
    );
    return content.replaceAll(regExp, '');
  }
}
