import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:merlmovie_client/src/extensions/list.dart';
import 'package:merlmovie_client/src/models/movie.dart';
import 'package:merlmovie_client/src/widgets/select_episode_listview.dart';
import 'package:merlmovie_client/src/widgets/select_season_listview.dart';

class PlayerSelectEpisodeSheet extends StatefulWidget {
  final List<Season> seasons;
  final Episode? currentEpisode;
  const PlayerSelectEpisodeSheet({
    super.key,
    required this.seasons,
    this.currentEpisode,
  });

  @override
  State<PlayerSelectEpisodeSheet> createState() =>
      _PlayerSelectEpisodeSheetState();
}

class _PlayerSelectEpisodeSheetState extends State<PlayerSelectEpisodeSheet> {
  Season? selectedSeason;
  Episode? selectedEpisode;

  int pageIndex = 0;

  PageController? controller;

  void update() => mounted ? setState(() {}) : () {};

  Future initialize() async {
    if (widget.currentEpisode != null) {
      selectedSeason = widget.seasons.firstWhereOrNull(
        (e) => e.seasonNumber == widget.currentEpisode?.seasonNumber,
      );
      selectedEpisode = selectedSeason?.episodes.firstWhereOrNull(
        (e) => e.episodeNumber == widget.currentEpisode?.episodeNumber,
      );
    }
    bool isSelectedSeason = selectedSeason != null && selectedSeason!.episodes.isNotEmpty;
    controller = PageController(initialPage: isSelectedSeason ? 1 : 0);
    pageIndex = isSelectedSeason ? 1 : 0;
    update();
  }

  void changeSeason(Season? season) {
    selectedSeason = season;
    pageIndex = 1;
    controller?.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    update();
  }

  void onCloseEpisodesView() {
    selectedSeason =
        selectedSeason = widget.seasons.firstWhereOrNull(
          (e) => e.seasonNumber == widget.currentEpisode?.seasonNumber,
        );
    pageIndex = 0;
    controller?.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    update();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.maxMobileWidth + 100,
      constraints: BoxConstraints(maxHeight: context.screen.height * .9),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          if (pageIndex == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Seasons",
                      style: context.theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: PageView(
              controller: controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SelectSeasonListview(
                  current: selectedSeason,
                  seasons: widget.seasons,
                  textColor: Colors.white,
                  onChanged: changeSeason,
                ),
                SelectEpisodeListview(
                  current: selectedEpisode,
                  currentSeason: selectedSeason,
                  episodes: selectedSeason?.episodes ?? [],
                  textColor: Colors.white,
                  onChanged: (episode) => Navigator.of(context).pop(episode),
                  onClose: onCloseEpisodesView,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
