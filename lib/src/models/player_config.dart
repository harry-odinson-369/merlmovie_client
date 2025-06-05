class MerlMovieClientPlayerCallback {
  void Function()? onDecideAsWatched;
  void Function(Duration position, Duration duration)? onPositionChanged;

  MerlMovieClientPlayerCallback({
    this.onDecideAsWatched,
    this.onPositionChanged,
  });
}
