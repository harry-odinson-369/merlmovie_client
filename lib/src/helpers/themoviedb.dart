import 'package:merlmovie_client/src/helpers/generate.dart';
import 'package:merlmovie_client/src/helpers/proxy.dart';

enum TMDBImageSize { original, w500, w400, w300, w200 }

List<String> _api_keys = [];

class TheMovieDbApi {
  static String getImage([
    String imagePath = "",
    TMDBImageSize size = TMDBImageSize.w500,
  ]) =>
      "https://images.tmdb.org/t/p/${size.name}${imagePath.startsWith("/") ? "" : "/"}$imagePath";

  static String v3([String path = ""]) => "https://api.themoviedb.org/3/$path";

  static List<String> get api_keys => _api_keys;
  static String get any_api_key {
    return api_keys[GenerateHelper.random(0, api_keys.length - 1)];
  }

  static void setApiKeys(List<String> keys) => _api_keys = keys;

  static String getTitleLogo(
    String mediaType,
    String mediaId, [
    TMDBImageSize size = TMDBImageSize.w500,
  ]) => MerlMovieHttpProxyService.base(
    "title-logo?media_id=$mediaId&media_type=$mediaType&size=${size.name}&api_key=$any_api_key",
  );
}
