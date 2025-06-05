enum TMDBImageSize { original, w500, w400, w300, w200 }

class TheMovieDbApi {
  static String getImage([
    String imagePath = "",
    TMDBImageSize size = TMDBImageSize.w500,
  ]) =>
      "https://images.tmdb.org/t/p/${size.name}${imagePath.startsWith("/") ? "" : "/"}$imagePath";
}
