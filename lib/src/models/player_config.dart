class MerlMovieClientPlayerConfig {
  void Function()? onDecideAsWatched;
  void Function(Duration position, Duration duration)? onPositionChanged;

  MerlMovieClientPlayerConfig({
    this.onDecideAsWatched,
    this.onPositionChanged,
  });
}
