// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/models/subtitle.dart';
import 'package:subtitle/subtitle.dart';
import 'package:video_player/video_player.dart';

class PlayerDisplayCaption extends StatelessWidget {
  final VideoPlayerController? controller;
  final List<Subtitle> subtitles;
  final SubtitleTheme? subtitleTheme;
  const PlayerDisplayCaption({
    super.key,
    this.controller,
    required this.subtitles,
    this.subtitleTheme,
  });

  static TextStyle getCaptionFontStyle(String text) {
    if (RegExp(r'[\u1780-\u17FF]').hasMatch(text)) {
      // Khmer
      return GoogleFonts.notoSansKhmer();
    } else if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
      // Arabic
      return GoogleFonts.notoNaskhArabic();
    } else if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      // Hindi, Sanskrit, Marathi (Devanagari)
      return GoogleFonts.notoSansDevanagari();
    } else if (RegExp(r'[\u0980-\u09FF]').hasMatch(text)) {
      // Bengali
      return GoogleFonts.notoSansBengali();
    } else if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(text)) {
      // Gurmukhi (Punjabi)
      return GoogleFonts.notoSansGurmukhi();
    } else if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(text)) {
      // Gujarati
      return GoogleFonts.notoSansGujarati();
    } else if (RegExp(r'[\u0B00-\u0B7F]').hasMatch(text)) {
      // Oriya (Odia)
      return GoogleFonts.notoSansOriya();
    } else if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) {
      // Tamil
      return GoogleFonts.notoSansTamil();
    } else if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(text)) {
      // Telugu
      return GoogleFonts.notoSansTelugu();
    } else if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(text)) {
      // Kannada
      return GoogleFonts.notoSansKannada();
    } else if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(text)) {
      // Malayalam
      return GoogleFonts.notoSansMalayalam();
    } else if (RegExp(r'[\u0E00-\u0E7F]').hasMatch(text)) {
      // Thai
      return GoogleFonts.notoSansThai();
    } else if (RegExp(r'[\u0E80-\u0EFF]').hasMatch(text)) {
      // Lao
      return GoogleFonts.notoSansLao();
    } else if (RegExp(
      r'[\u1100-\u11FF\u3130-\u318F\uAC00-\uD7AF]',
    ).hasMatch(text)) {
      // Korean Hangul
      return GoogleFonts.notoSansKr();
    } else if (RegExp(
      r'[\u3040-\u30FF\u31F0-\u31FF\uFF66-\uFF9F]',
    ).hasMatch(text)) {
      // Japanese Hiragana/Katakana
      return GoogleFonts.notoSansJp();
    } else if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(text)) {
      // Chinese (Han)
      return GoogleFonts.notoSansSc(); // Simplified
    } else if (RegExp(r'[\u0400-\u04FF]').hasMatch(text)) {
      // Cyrillic (Russian, Ukrainian, etc.)
      return GoogleFonts.notoSans();
    } else if (RegExp(r'[\u0100-\u017F]').hasMatch(text)) {
      // Latin Extended-A
      return GoogleFonts.notoSans();
    } else {
      // Default Latin fallback
      return GoogleFonts.notoSans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder(
        valueListenable: controller!,
        builder: (context, value, child) {
          final caption = subtitles.firstWhereOrNull(
            (e) => value.position >= e.start && value.position <= e.end,
          );
          if (caption == null) {
            return const SizedBox();
          }
          return SizedBox(
            width: context.screen.width * .70,
            child: Text(
              caption.data.isNotEmpty ? "‎ ${caption.data} ‎" : "",
              textAlign: TextAlign.center,
              style: getCaptionFontStyle(caption.data).copyWith(
                fontSize: subtitleTheme?.fontSize ?? 18,
                color: subtitleTheme?.textColor ?? Colors.white,
                fontWeight: subtitleTheme?.fontWeight ?? FontWeight.w500,
                backgroundColor:
                    subtitleTheme?.backgroundColor.withOpacity(
                      subtitleTheme?.backgroundOpacity ?? .8,
                    ) ??
                    Colors.black.withOpacity(.8),
                fontStyle: subtitleTheme?.fontStyle,
              ),
            ),
          );
        },
      ),
    );
  }
}
