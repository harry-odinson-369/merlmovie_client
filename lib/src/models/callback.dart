import 'package:merlmovie_client/src/models/embed.dart';

class MerlMovieClientPlayerCallback {
  void Function(EmbedModel embed)? onDecideAsWatched;
  void Function(EmbedModel embed, Duration position, Duration duration)? onPositionChanged;

  MerlMovieClientPlayerCallback({
    this.onDecideAsWatched,
    this.onPositionChanged,
  });
}
