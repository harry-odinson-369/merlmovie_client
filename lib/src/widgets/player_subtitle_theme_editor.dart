// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/extensions/string.dart';
import 'package:merlmovie_client/src/global/global.vars.dart';
import 'package:merlmovie_client/src/models/subtitle.dart';

class PlayerSubtitleThemeEditor extends StatelessWidget {
  final SubtitleTheme current;
  final void Function(SubtitleTheme theme)? onChanged;
  final void Function()? onClose;
  const PlayerSubtitleThemeEditor({
    super.key,
    required this.current,
    this.onChanged,
    this.onClose,
  });

  Future<Color> pickColor(Color current) async {
    Color? color = await showDialog<Color?>(
      context: NavigatorKey.currentContext!,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade400,
            content: SizedBox(
              width: 400,
              height: 340,
              child: BlockPicker(
                availableColors: const [
                  Colors.red,
                  Colors.pink,
                  Colors.purple,
                  Colors.deepPurple,
                  Colors.indigo,
                  Colors.blue,
                  Colors.lightBlue,
                  Colors.cyan,
                  Colors.teal,
                  Colors.green,
                  Colors.lightGreen,
                  Colors.lime,
                  Colors.yellow,
                  Colors.amber,
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.brown,
                  Colors.grey,
                  Colors.blueGrey,
                  Colors.white,
                  Colors.black,
                ],
                pickerColor: current,
                onColorChanged: (value) {
                  Navigator.of(ctx).pop(value);
                },
              ),
            ),
          ),
    );
    return color ?? current;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 12,
          left: 12,
          bottom: current.bottomPad,
          child: SizedBox(
            width: context.screen.width * .70,
            child: Text(
              "‎ Lorem Ipsum is simply dummy text of the printing and typesetting industry. ‎",
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans().copyWith(
                fontSize: current.fontSize,
                color: current.textColor,
                fontWeight: current.fontWeight,
                backgroundColor: current.backgroundColor.withOpacity(
                  current.backgroundOpacity,
                ),
                fontStyle: current.fontStyle,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          left: 0,
          child: ExpansionTile(
            backgroundColor: Colors.black.withOpacity(.76),
            initiallyExpanded: true,
            collapsedBackgroundColor: Colors.black.withOpacity(.76),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            collapsedShape: Border.all(color: Colors.transparent),
            shape: Border.all(color: Colors.transparent),
            title: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 24),
                  const Text(
                    "Subtitle Theme",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            slider(
                              "Position",
                              onChanged: (value) {
                                onChanged?.call(
                                  current.copyWith(bottomPad: value),
                                );
                              },
                              value: current.bottomPad,
                              max: context.screen.height / 2,
                              sliderWidth: context.screen.width / 3,
                            ),
                            slider(
                              "Text Size",
                              onChanged: (value) {
                                onChanged?.call(
                                  current.copyWith(fontSize: value),
                                );
                              },
                              value: current.fontSize,
                              max: 32,
                              min: 12,
                              sliderWidth: context.screen.width / 3,
                            ),
                            slider(
                              "Background Opacity",
                              onChanged: (value) {
                                onChanged?.call(
                                  current.copyWith(backgroundOpacity: value),
                                );
                              },
                              value: current.backgroundOpacity,
                              max: 1,
                              min: 0,
                              sliderWidth: context.screen.width / 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            popup(
                              "FontStyle: ",
                              value: current.fontStyle.name.capitalize,
                              items: [
                                ...FontStyle.values.build((e, i) {
                                  bool selected =
                                      e.name == current.fontStyle.name;
                                  return PopupMenuItem(
                                    value: e.name,
                                    onTap: () {
                                      onChanged?.call(
                                        current.copyWith(fontStyle: e),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        selected
                                            ? const Icon(Icons.done)
                                            : const SizedBox(width: 24),
                                        SizedBox(width: 12),
                                        Text(
                                          e.name.capitalize,
                                          style:
                                              context.theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 14),
                            popup(
                              "FontWeight: ",
                              value: "w${current.fontWeight.value}",
                              items: [
                                ...FontWeight.values.build((e, i) {
                                  bool selected = e.value == current.fontWeight.value;
                                  return PopupMenuItem(
                                    value: e.value.toString(),
                                    onTap: () {
                                      onChanged?.call(
                                        current.copyWith(fontWeight: e),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        selected
                                            ? const Icon(Icons.done)
                                            : const SizedBox(width: 24),
                                        SizedBox(width: 12),
                                        Text(
                                          "w${e.value.toString()}",
                                          style:
                                              context.theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 14),
                            colorChanger(
                              "Text Color",
                              value: current.textColor,
                              onChanged: (color) {
                                onChanged?.call(
                                  current.copyWith(textColor: color),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            colorChanger(
                              "Background Color",
                              value: current.backgroundColor,
                              onChanged: (color) {
                                onChanged?.call(
                                  current.copyWith(backgroundColor: color),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget colorChanger(
    String label, {
    void Function(Color color)? onChanged,
    Color? value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "$label: ",
          style: TextStyle(color: Colors.white.withOpacity(.8), fontSize: 14),
        ),
        const SizedBox(width: 12),
        Text(
          (value ?? Colors.white).toHexString(),
          style: TextStyle(color: Colors.white.withOpacity(.8), fontSize: 14),
        ),
        InkWell(
          onTap: () async {
            Color color = await pickColor(value ?? Colors.white);
            onChanged?.call(color);
          },
          child: Container(
            height: 30,
            width: 30,
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: value ?? Colors.white,
              border: Border.all(color: Colors.grey.shade200, width: .5),
            ),
          ),
        ),
      ],
    );
  }

  Widget popup(
    String label, {
    String value = "",
    List<PopupMenuItem> items = const [],
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(.8), fontSize: 14),
        ),
        PopupMenuButton(
          itemBuilder: (context) => items,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(value, style: const TextStyle(color: Colors.white)),
                const SizedBox(width: 12),
                const RotatedBox(
                  quarterTurns: 1,
                  child: Icon(CupertinoIcons.forward, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget slider(
    String label, {
    double value = 0,
    double min = 0,
    double max = 1,
    void Function(double val)? onChanged,
    double? sliderWidth,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label (${value.toStringAsFixed(1)})",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        SliderTheme(
          data: SliderThemeData(inactiveTrackColor: Colors.white54),
          child: Slider(
            value: value,
            activeColor: Colors.red,
            onChanged: onChanged,
            min: min,
            max: max,
          ),
        ),
      ],
    );
  }
}
