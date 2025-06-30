// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/models/direct_link.dart';
import 'package:merlmovie_client/src/widgets/scroll_to_index.dart';

class SelectSubtitleChildListview extends StatefulWidget {
  final SubtitleItem? current;
  final SubtitleItem temp;
  final void Function(SubtitleItem newSubtitle)? onClose;
  final void Function(SubtitleItem subtitle)? onChanged;
  final String? season, episode;
  const SelectSubtitleChildListview({
    super.key,
    required this.current,
    required this.temp,
    this.onClose,
    this.onChanged,
    this.season,
    this.episode,
  });

  @override
  State<SelectSubtitleChildListview> createState() =>
      _SelectSubtitleChildListviewState();
}

class _SelectSubtitleChildListviewState
    extends State<SelectSubtitleChildListview> {
  bool isLoading = true;

  List<Map<String, dynamic>> dynamic_subtitles = [];

  late AutoScrollController controller;

  void update() => mounted ? setState(() {}) : () {};

  Future initialize() async {
    if (widget.temp.children.isEmpty) {
      Response response = await get(
        Uri.parse(widget.temp.link),
        headers: widget.temp.headers,
      );
      if (response.statusCode == HttpStatus.ok) {
        final results = await compute(
          (message) => json.decode(message),
          response.body,
        );
        final subtitles = List<Map<String, dynamic>>.from(results);
        if (widget.season != null && widget.episode != null) {
          dynamic_subtitles =
              subtitles.where((e) {
                return e[widget.temp.key?.seasonKey ?? "___"] ==
                        widget.season &&
                    e[widget.temp.key?.episodeKey ?? "___"] == widget.episode;
              }).toList();
        } else {
          dynamic_subtitles = subtitles;
        }
      }
    } else {
      dynamic_subtitles = widget.temp.children;
    }
    isLoading = false;
    update();
  }

  @override
  void initState() {
    super.initState();
    controller = AutoScrollController(axis: Axis.vertical);
    update();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      int index = widget.temp.children.indexWhere(
        (e) =>
            e[widget.temp.key?.linkKey ?? "___"] == widget.current?.real_link,
      );
      if (index != -1) {
        controller.scrollToIndex(
          index,
          duration: const Duration(milliseconds: 150),
          preferPosition: AutoScrollPosition.middle,
        );
      }
    });
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.temp.children = dynamic_subtitles;
        widget.onClose?.call(widget.temp);
        return true;
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    widget.temp.children = dynamic_subtitles;
                    widget.onClose?.call(widget.temp);
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      widget.temp.name,
                      maxLines: 1,
                      style: context.theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : !isLoading && dynamic_subtitles.isEmpty
                    ? Center(
                      child: Text(
                        "No subtitles for ${widget.temp.name}.",
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    )
                    : ListView(
                      shrinkWrap: true,
                      controller: controller,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        ...dynamic_subtitles.build((e, i) {
                          String? link = e[widget.temp.key?.linkKey ?? "___"];
                          String? name = e[widget.temp.key?.nameKey ?? "___"];
                          bool isSelected = link == widget.current?.real_link;
                          String? format = e[widget.temp.key?.formatKey ?? "___"];
                          List<String> arr_spp = ["srt", "vtt"];
                          bool isSupported = arr_spp.contains(format.toString());
                          if (!isSupported) {
                            return SizedBox();
                          }
                          return InkWell(
                            onTap: () {
                              widget.temp.children = dynamic_subtitles;
                              widget.temp.real_link = link;
                              widget.onChanged?.call(widget.temp);
                            },
                            borderRadius: BorderRadius.circular(10),
                            splashFactory: NoSplash.splashFactory,
                            splashColor: Colors.transparent,
                            child: AutoScrollTag(
                              index: i,
                              key: Key("subtitle_child_$i"),
                              controller: controller,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(width: 24),
                                    if (isSelected)
                                      Icon(
                                        Icons.done,
                                        size: 26,
                                        color: Colors.white,
                                      ),
                                    if (!isSelected) SizedBox(width: 26),
                                    SizedBox(width: 24),
                                    Flexible(
                                      child: Text(
                                        name.toString(),
                                        maxLines: 2,
                                        style: context
                                            .theme
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        SizedBox(height: 60),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
