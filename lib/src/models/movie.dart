import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/extensions/list.dart';

class MovieModel {
  String backdropPath;
  int id;
  String originalName;
  String overview;
  String posterPath;
  String mediaType;
  bool adult;
  String name;
  String title;
  String originalLanguage;
  List<int> genreIds;
  double popularity;
  String firstAirDate;
  String releasedDate;
  double voteAverage;
  int voteCount;
  List<String> originCountry;
  String imdbId;
  int runtime;
  String? titleLogo;

  MovieModel({
    required this.backdropPath,
    required this.id,
    required this.originalName,
    required this.overview,
    required this.posterPath,
    required this.mediaType,
    required this.adult,
    required this.name,
    required this.title,
    required this.originalLanguage,
    required this.genreIds,
    required this.popularity,
    required this.firstAirDate,
    required this.releasedDate,
    required this.voteAverage,
    required this.voteCount,
    required this.originCountry,
    required this.imdbId,
    required this.runtime,
    required this.titleLogo,
  });

  String get unique => "$type-$id";

  String get type => name.isNotEmpty ? "tv" : "movie";

  String get real_title => type == "tv" ? name : title;

  String get real_year =>
      firstAirDate.isNotEmpty
          ? firstAirDate.split("-").firstWhereOrNull((e) => e.length == 4) ?? ""
          : releasedDate.split("-").firstWhereOrNull((e) => e.length == 4) ??
              "";

  factory MovieModel.fromJson(Map<String, dynamic> json) => MovieModel(
    backdropPath: json["backdrop_path"] ?? "",
    id: json["id"] ?? 0,
    originalName: json["original_name"] ?? "",
    overview: json["overview"] ?? "",
    posterPath: json["poster_path"] ?? "",
    mediaType: json["media_type"] ?? "",
    adult: json["adult"] ?? false,
    name: json["name"] ?? "",
    title: json["title"] ?? "",
    originalLanguage: json["original_language"] ?? "",
    genreIds: List<int>.from((json["genre_ids"] ?? []).map((x) => x)),
    popularity: double.parse("${json["popularity"] ?? 0}"),
    firstAirDate: json["first_air_date"] ?? "",
    releasedDate: json["release_date"] ?? "",
    voteAverage: double.parse("${json["vote_average"] ?? 0}"),
    voteCount: json["vote_count"] ?? 0,
    originCountry: List<String>.from(
      (json["origin_country"] ?? []).map((x) => x),
    ),
    imdbId: json["imdb_id"] ?? "",
    runtime: json["runtime"] ?? 0,
    titleLogo: json["title_logo"],
  );

  Map<String, dynamic> toJson({String? imdb, int? run, String? tLogo}) => {
    "backdrop_path": backdropPath,
    "id": id,
    "original_name": originalName,
    "overview": overview,
    "poster_path": posterPath,
    "media_type": mediaType,
    "adult": adult,
    "name": name,
    "title": title,
    "original_language": originalLanguage,
    "genre_ids": List<dynamic>.from(genreIds.map((x) => x)),
    "popularity": popularity,
    "first_air_date": firstAirDate,
    "release_date": releasedDate,
    "vote_average": voteAverage,
    "vote_count": voteCount,
    "origin_country": List<dynamic>.from(originCountry.map((x) => x)),
    "imdb_id": imdb ?? imdbId,
    "runtime": run ?? runtime,
    "title_logo": titleLogo ?? tLogo,
  };
}

class DetailModel {
  bool adult;
  String backdropPath;
  BelongsToCollection? belongsToCollection;
  int budget;
  List<dynamic> episodeRunTime;
  List<Genre> genres;
  String homepage;
  int id;
  String originalLanguage;
  String originalTitle;
  String originalName;
  String overview;
  double popularity;
  String posterPath;
  List<ProductionCompany> productionCompanies;
  List<ProductionCompany> networks;
  List<ProductionCountry> productionCountries;
  String releaseDate;
  String firstAirDate;
  String lastAirDate;
  int revenue;
  int runtime;
  List<Season> seasons;
  List<SpokenLanguage> spokenLanguages;
  String status;
  String tagline;
  String title;
  String name;
  bool video;
  double voteAverage;
  int voteCount;
  Videos videos;
  Images images;
  Credits credits;
  Recommendations recommendations;
  Recommendations similar;
  ExternalIds externalIds;
  ReviewsModel reviews;

  Color? platte;

  Color? get textColor {
    return (platte?.computeLuminance() ?? .5) > .3
        ? Colors.black
        : Colors.white;
  }

  String get real_title_logo {
    final highestRated = images.highestRatedLogo;
    if (highestRated.filePath.isNotEmpty) {
      return highestRated.filePath;
    } else {
      return images.firstAnyImageFormatLogo.filePath;
    }
  }

  DetailModel({
    required this.adult,
    required this.backdropPath,
    required this.belongsToCollection,
    required this.episodeRunTime,
    required this.budget,
    required this.genres,
    required this.homepage,
    required this.id,
    required this.originalLanguage,
    required this.originalTitle,
    required this.originalName,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.productionCompanies,
    required this.networks,
    required this.productionCountries,
    required this.releaseDate,
    required this.firstAirDate,
    required this.lastAirDate,
    required this.revenue,
    required this.runtime,
    required this.seasons,
    required this.spokenLanguages,
    required this.status,
    required this.tagline,
    required this.title,
    required this.name,
    required this.video,
    required this.voteAverage,
    required this.voteCount,
    required this.videos,
    required this.images,
    required this.credits,
    required this.recommendations,
    required this.similar,
    required this.externalIds,
    required this.reviews,
  });

  String get type => name.isNotEmpty ? "tv" : "movie";

  String get unique => "$type-$id";

  String get real_title => type == "tv" ? name : title;

  String get real_released_date => type == "tv" ? firstAirDate : releaseDate;

  String get real_year =>
      firstAirDate.isNotEmpty
          ? firstAirDate.split("-").firstWhereOrNull((e) => e.length == 4) ??
              "..."
          : releaseDate.split("-").firstWhereOrNull((e) => e.length == 4) ??
              "...";

  String get real_original_title => type == "tv" ? originalName : originalTitle;

  factory DetailModel.fromMap(Map<String, dynamic> json) => DetailModel(
    adult: json["adult"] ?? false,
    backdropPath: json["backdrop_path"] ?? "",
    belongsToCollection:
        json["belongs_to_collection"] != null
            ? BelongsToCollection.fromMap(json["belongs_to_collection"] ?? {})
            : null,
    budget: json["budget"] ?? 0,
    episodeRunTime: List<dynamic>.from(
      (json["episode_run_time"] ?? []).map((x) => x),
    ),
    genres: List<Genre>.from(
      (json["genres"] ?? []).map((x) => Genre.fromMap(x)),
    ),
    homepage: json["homepage"] ?? "",
    id: json["id"] ?? 0,
    originalLanguage: json["original_language"] ?? "",
    originalTitle: json["original_title"] ?? "",
    originalName: json["original_name"] ?? "",
    overview: json["overview"] ?? "",
    popularity: (json["popularity"] ?? 0).toDouble(),
    posterPath: json["poster_path"] ?? "",
    productionCompanies: List<ProductionCompany>.from(
      (json["production_companies"] ?? []).map(
        (x) => ProductionCompany.fromMap(x),
      ),
    ),
    networks: List<ProductionCompany>.from(
      (json["networks"] ?? []).map((x) => ProductionCompany.fromMap(x)),
    ),
    productionCountries: List<ProductionCountry>.from(
      (json["production_countries"] ?? []).map(
        (x) => ProductionCountry.fromMap(x),
      ),
    ),
    releaseDate: json["release_date"] ?? "",
    firstAirDate: json["first_air_date"] ?? "",
    lastAirDate: json["last_air_date"] ?? "",
    revenue: json["revenue"] ?? 0,
    runtime: json["runtime"] ?? 0,
    seasons: List<Season>.from(
      (json["seasons"] ?? []).map((x) => Season.fromJson(x)),
    ),
    spokenLanguages: List<SpokenLanguage>.from(
      (json["spoken_languages"] ?? []).map((x) => SpokenLanguage.fromMap(x)),
    ),
    status: json["status"] ?? "",
    tagline: json["tagline"] ?? "",
    title: json["title"] ?? "",
    name: json["name"] ?? "",
    video: json["video"] ?? false,
    voteAverage: (json["vote_average"] ?? 0).toDouble(),
    voteCount: json["vote_count"] ?? 0,
    videos: Videos.fromMap(json["videos"] ?? {}),
    images: Images.fromMap(json["images"] ?? {}),
    credits: Credits.fromMap(json["credits"] ?? {}),
    recommendations: Recommendations.fromMap(json["recommendations"] ?? {}),
    similar: Recommendations.fromMap(json["similar"] ?? {}),
    externalIds: ExternalIds.fromJson(json["external_ids"] ?? {}),
    reviews: ReviewsModel.fromJson(json["reviews"] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    "adult": adult,
    "backdrop_path": backdropPath,
    "belongs_to_collection": belongsToCollection?.toMap(),
    "episode_run_time": List<dynamic>.from(episodeRunTime.map((x) => x)),
    "first_air_date": firstAirDate,
    "genres": List<dynamic>.from(genres.map((x) => x.toMap())),
    "homepage": homepage,
    "id": id,
    "last_air_date": lastAirDate,
    "name": name,
    "original_language": originalLanguage,
    "original_title": originalTitle,
    "original_name": originalName,
    "overview": overview,
    "popularity": popularity,
    "poster_path": posterPath,
    "production_companies": List<dynamic>.from(
      productionCompanies.map((x) => x.toMap()),
    ),
    "networks": List<dynamic>.from(networks.map((x) => x.toMap())),
    "production_countries": List<dynamic>.from(
      productionCountries.map((x) => x.toMap()),
    ),
    "seasons": List<dynamic>.from(seasons.map((x) => x.toJson())),
    "spoken_languages": List<dynamic>.from(
      spokenLanguages.map((x) => x.toMap()),
    ),
    "status": status,
    "tagline": tagline,
    "type": type,
    "title": title,
    "vote_average": voteAverage,
    "vote_count": voteCount,
    "videos": videos.toMap(),
    "images": images.toMap(),
    "release_date": releaseDate,
    "runtime": runtime,
    "revenue": revenue,
    "budget": budget,
    "recommendations": recommendations.toMap(),
    "similar": similar.toMap(),
    "credits": credits.toMap(),
    "external_ids": externalIds.toJson(),
    "reviews": reviews.toJson(),
  };
}

class BelongsToCollection {
  int id;
  String name;
  String posterPath;
  String backdropPath;

  String get openingId => "$name-$id";

  BelongsToCollection({
    required this.id,
    required this.name,
    required this.posterPath,
    required this.backdropPath,
  });

  factory BelongsToCollection.fromMap(Map<String, dynamic> json) =>
      BelongsToCollection(
        id: json["id"] ?? 0,
        name: json["name"] ?? "",
        posterPath: json["poster_path"] ?? "",
        backdropPath: json["backdrop_path"] ?? "",
      );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "poster_path": posterPath,
    "backdrop_path": backdropPath,
  };
}

class Genre {
  int id;
  String name;

  Genre({required this.id, required this.name});

  factory Genre.fromMap(Map<String, dynamic> json) =>
      Genre(id: json["id"] ?? 0, name: json["name"] ?? 0);

  Map<String, dynamic> toMap() => {"id": id, "name": name};
}

class ProductionCompany {
  int id;
  String? logoPath;
  String name;
  String originCountry;

  ProductionCompany({
    required this.id,
    required this.logoPath,
    required this.name,
    required this.originCountry,
  });

  factory ProductionCompany.fromMap(Map<String, dynamic> json) =>
      ProductionCompany(
        id: json["id"] ?? 0,
        logoPath: json["logo_path"] ?? "",
        name: json["name"] ?? "",
        originCountry: json["origin_country"] ?? "",
      );

  Map<String, dynamic> toMap() => {
    "id": id,
    "logo_path": logoPath,
    "name": name,
    "origin_country": originCountry,
  };
}

class ProductionCountry {
  String iso31661;
  String name;

  ProductionCountry({required this.iso31661, required this.name});

  factory ProductionCountry.fromMap(Map<String, dynamic> json) =>
      ProductionCountry(
        iso31661: json["iso_3166_1"] ?? "",
        name: json["name"] ?? "",
      );

  Map<String, dynamic> toMap() => {"iso_3166_1": iso31661, "name": name};
}

class Season {
  String airDate;
  int episodeCount;
  int id;
  String name;
  String overview;
  String posterPath;
  int seasonNumber;
  double voteAverage;
  List<Episode> episodes;

  Season({
    required this.airDate,
    required this.episodeCount,
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.seasonNumber,
    required this.voteAverage,
    required this.episodes,
  });

  factory Season.fromJson(Map<String, dynamic> json) => Season(
    airDate: json["air_date"] ?? "",
    episodeCount: json["episode_count"] ?? 0,
    id: json["id"] ?? 0,
    name: json["name"] ?? "",
    overview: json["overview"] ?? "",
    posterPath: json["poster_path"] ?? "",
    seasonNumber: json["season_number"] ?? 0,
    voteAverage: (json["vote_average"] ?? 0).toDouble(),
    episodes: List<Episode>.from(
      (json["episodes"] ?? []).map((x) => Episode.fromMap(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "air_date": airDate,
    "episode_count": episodeCount,
    "id": id,
    "name": name,
    "overview": overview,
    "poster_path": posterPath,
    "season_number": seasonNumber,
    "vote_average": voteAverage,
    "episodes": List<dynamic>.from(episodes.map((x) => x.toMap())),
  };
}

class SpokenLanguage {
  String englishName;
  String iso6391;
  String name;

  SpokenLanguage({
    required this.englishName,
    required this.iso6391,
    required this.name,
  });

  factory SpokenLanguage.fromMap(Map<String, dynamic> json) => SpokenLanguage(
    englishName: json["english_name"] ?? "",
    iso6391: json["iso_639_1"] ?? "",
    name: json["name"] ?? "",
  );

  Map<String, dynamic> toMap() => {
    "english_name": englishName,
    "iso_639_1": iso6391,
    "name": name,
  };
}

class Images {
  List<ImagePath> backdrops;
  List<ImagePath> logos;
  List<ImagePath> posters;

  Images({required this.backdrops, required this.logos, required this.posters});

  List<ImagePath> get englishLogos =>
      logos.where((e) => e.iso6391 == "en").toList();

  ImagePath get highestRatedLogo {
    if (logos.isEmpty) return ImagePath.fromJson({});
    final ls = (englishLogos.isNotEmpty ? englishLogos : logos);
    double highestVoteAverage = 0;
    ImagePath votedItem = ImagePath.fromJson({});
    for (var item in ls) {
      if ((item.voteAverage > highestVoteAverage &&
              item.filePath.endsWith(".png")) ||
          item.filePath.endsWith(".jpeg") ||
          item.filePath.endsWith(".jpg")) {
        highestVoteAverage = item.voteAverage;
        votedItem = item;
        debugPrint("Highest rated logo: ${item.voteAverage}");
      }
    }

    return votedItem;
  }

  ImagePath get firstAnyImageFormatLogo {
    ImagePath image = ImagePath.fromJson({});

    final ls = (englishLogos.isNotEmpty ? englishLogos : logos);

    for (var item in ls) {
      if (item.filePath.endsWith(".png") ||
          item.filePath.endsWith(".jpeg") ||
          item.filePath.endsWith(".jpg")) {
        image = item;
        break;
      }
    }

    return image;
  }

  factory Images.fromMap(Map<String, dynamic> json) => Images(
    backdrops: List<ImagePath>.from(
      (json["backdrops"] ?? []).map((x) => ImagePath.fromJson(x)),
    ),
    logos: List<ImagePath>.from(
      (json["logos"] ?? []).map((x) => ImagePath.fromJson(x)),
    ),
    posters: List<ImagePath>.from(
      (json["posters"] ?? []).map((x) => ImagePath.fromJson(x)),
    ),
  );

  Map<String, dynamic> toMap() => {
    "backdrops": List<dynamic>.from(backdrops.map((x) => x.toJson())),
    "logos": List<dynamic>.from(logos.map((x) => x.toJson())),
    "posters": List<dynamic>.from(posters.map((x) => x.toJson())),
  };
}

class Credits {
  List<Cast> cast;
  List<Cast> crew;

  Credits({required this.cast, required this.crew});

  factory Credits.fromMap(Map<String, dynamic> json) => Credits(
    cast: List<Cast>.from((json["cast"] ?? []).map((x) => Cast.fromMap(x))),
    crew: List<Cast>.from((json["crew"] ?? []).map((x) => Cast.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "cast": List<dynamic>.from(cast.map((x) => x.toMap())),
    "crew": List<dynamic>.from(crew.map((x) => x.toMap())),
  };
}

class Cast {
  bool adult;
  int gender;
  int id;
  String knownForDepartment;
  String name;
  String originalName;
  double popularity;
  String profilePath;
  int? castId;
  String character;
  String creditId;
  int? order;
  String department;
  String job;
  List<MovieModel> knownFor;

  Cast({
    required this.adult,
    required this.gender,
    required this.id,
    required this.knownForDepartment,
    required this.name,
    required this.originalName,
    required this.popularity,
    required this.profilePath,
    this.castId,
    required this.character,
    required this.creditId,
    this.order,
    required this.department,
    required this.job,
    required this.knownFor,
  });

  factory Cast.fromMap(Map<String, dynamic> json) => Cast(
    adult: json["adult"] ?? false,
    gender: json["gender"] ?? 0,
    id: json["id"] ?? 0,
    knownForDepartment: json["known_for_department"] ?? "",
    name: json["name"] ?? "",
    originalName: json["original_name"] ?? "",
    popularity: (json["popularity"] ?? 0).toDouble(),
    profilePath: json["profile_path"] ?? "",
    castId: json["cast_id"] ?? 0,
    character: json["character"] ?? "",
    creditId: json["credit_id"] ?? "",
    order: json["order"] ?? 0,
    department: json["department"] ?? "",
    job: json["job"] ?? "",
    knownFor: List<MovieModel>.from(
      (json["known_for"] ?? []).map((x) => MovieModel.fromJson(x)),
    ),
  );

  Map<String, dynamic> toMap() => {
    "adult": adult,
    "gender": gender,
    "id": id,
    "known_for_department": knownForDepartment,
    "name": name,
    "original_name": originalName,
    "popularity": popularity,
    "profile_path": profilePath,
    "cast_id": castId,
    "character": character,
    "credit_id": creditId,
    "order": order,
    "department": department,
    "job": job,
    "known_for": List<dynamic>.from(knownFor.map((x) => x.toJson())),
  };
}

class Videos {
  List<Result> results;

  Videos({required this.results});

  factory Videos.fromMap(Map<String, dynamic> json) => Videos(
    results: List<Result>.from(
      (json["results"] ?? []).map((x) => Result.fromMap(x)),
    ),
  );

  List<Result> get youtubeVideos =>
      results.where((e) => e.site.toLowerCase() == "youtube").toList();

  List<Result> get youtubeTrailerOnly =>
      youtubeVideos.where((e) => e.type.toLowerCase() == "trailer").toList();

  Map<String, dynamic> toMap() => {
    "results": List<dynamic>.from(results.map((x) => x.toMap())),
  };
}

class Result {
  String iso6391;
  String iso31661;
  String name;
  String key;
  String site;
  int size;
  String type;
  bool official;
  String publishedAt;
  String id;

  Result({
    required this.iso6391,
    required this.iso31661,
    required this.name,
    required this.key,
    required this.site,
    required this.size,
    required this.type,
    required this.official,
    required this.publishedAt,
    required this.id,
  });

  factory Result.fromMap(Map<String, dynamic> json) => Result(
    iso6391: json["iso_639_1"] ?? "",
    iso31661: json["iso_3166_1"] ?? "",
    name: json["name"] ?? "",
    key: json["key"] ?? "",
    site: json["site"] ?? "",
    size: json["size"] ?? 0,
    type: json["type"] ?? "",
    official: json["official"] ?? false,
    publishedAt: json["published_at"] ?? "",
    id: json["id"] ?? "",
  );

  Map<String, dynamic> toMap() => {
    "iso_639_1": iso6391,
    "iso_3166_1": iso31661,
    "name": name,
    "key": key,
    "site": site,
    "size": size,
    "type": type,
    "official": official,
    "published_at": publishedAt,
    "id": id,
  };
}

class Recommendations {
  int page;
  List<MovieModel> results;
  int totalPages;
  int totalResults;

  Recommendations({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory Recommendations.fromMap(Map<String, dynamic> json) => Recommendations(
    page: json["page"] ?? 0,
    results: List<MovieModel>.from(
      (json["results"] ?? []).map((x) => MovieModel.fromJson(x)),
    ),
    totalPages: json["total_pages"] ?? 0,
    totalResults: json["total_results"] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    "page": page,
    "results": List<dynamic>.from(results.map((x) => x.toJson())),
    "total_pages": totalPages,
    "total_results": totalResults,
  };
}

class ExternalIds {
  String imdbId;
  String wikidataId;
  String facebookId;
  String instagramId;
  String twitterId;

  ExternalIds({
    required this.imdbId,
    required this.wikidataId,
    required this.facebookId,
    required this.instagramId,
    required this.twitterId,
  });

  factory ExternalIds.fromJson(Map<String, dynamic> json) => ExternalIds(
    imdbId: json["imdb_id"] ?? "",
    wikidataId: json["wikidata_id"] ?? "",
    facebookId: json["facebook_id"] ?? "",
    instagramId: json["instagram_id"] ?? "",
    twitterId: json["twitter_id"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "imdb_id": imdbId,
    "wikidata_id": wikidataId,
    "facebook_id": facebookId,
    "instagram_id": instagramId,
    "twitter_id": twitterId,
  };
}

class ImagePath {
  double aspectRatio;
  int height;
  String? iso6391;
  String filePath;
  double voteAverage;
  int voteCount;
  int width;

  ImagePath({
    required this.aspectRatio,
    required this.height,
    required this.iso6391,
    required this.filePath,
    required this.voteAverage,
    required this.voteCount,
    required this.width,
  });

  factory ImagePath.fromJson(Map<String, dynamic> json) => ImagePath(
    aspectRatio: double.parse("${json["aspect_ratio"] ?? 0.0}"),
    height: json["height"] ?? 0,
    iso6391: json["iso_639_1"] ?? "",
    filePath: json["file_path"] ?? "",
    voteAverage: double.parse("${json["vote_average"] ?? 0.0}"),
    voteCount: json["vote_count"] ?? 0,
    width: json["width"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "aspect_ratio": aspectRatio,
    "height": height,
    "iso_639_1": iso6391,
    "file_path": filePath,
    "vote_average": voteAverage,
    "vote_count": voteCount,
    "width": width,
  };
}

class ReviewsModel {
  int id;
  int page;
  List<ReviewModel> results;
  int totalPages;
  int totalResults;

  ReviewsModel({
    required this.id,
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory ReviewsModel.fromJson(Map<String, dynamic> json) => ReviewsModel(
    id: json["id"] ?? 0,
    page: json["page"] ?? 0,
    results: List<ReviewModel>.from(
      (json["results"] ?? []).map((x) => ReviewModel.fromJson(x)),
    ),
    totalPages: json["total_pages"] ?? 0,
    totalResults: json["total_results"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "page": page,
    "results": List<dynamic>.from(results.map((x) => x.toJson())),
    "total_pages": totalPages,
    "total_results": totalResults,
  };

  ReviewModel get firstHighestRated {
    ReviewModel review = ReviewModel.fromJson({});
    double rated = 0.0;

    for (var item in results) {
      if (rated < item.authorDetails.rating) {
        rated = item.authorDetails.rating;
        review = item;
      }
    }

    return review;
  }
}

class ReviewModel {
  String author;
  AuthorDetails authorDetails;
  String content;
  String createdAt;
  String id;
  String updatedAt;
  String url;

  ReviewModel({
    required this.author,
    required this.authorDetails,
    required this.content,
    required this.createdAt,
    required this.id,
    required this.updatedAt,
    required this.url,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    author: json["author"] ?? "",
    authorDetails: AuthorDetails.fromJson(json["author_details"] ?? {}),
    content: json["content"] ?? "",
    createdAt: json["created_at"] ?? "",
    id: json["id"] ?? "",
    updatedAt: json["updated_at"] ?? "",
    url: json["url"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "author": author,
    "author_details": authorDetails.toJson(),
    "content": content,
    "created_at": createdAt,
    "id": id,
    "updated_at": updatedAt,
    "url": url,
  };
}

class AuthorDetails {
  String name;
  String username;
  String avatarPath;
  double rating;

  AuthorDetails({
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.rating,
  });

  factory AuthorDetails.fromJson(Map<String, dynamic> json) => AuthorDetails(
    name: json["name"] ?? "",
    username: json["username"] ?? "",
    avatarPath: json["avatar_path"] ?? "",
    rating: json["rating"] ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "username": username,
    "avatar_path": avatarPath,
    "rating": rating,
  };
}

class Episode {
  String airDate;
  int episodeNumber;
  String episodeType;
  int id;
  String name;
  String overview;
  String productionCode;
  int runtime;
  int seasonNumber;
  int showId;
  String stillPath;
  double voteAverage;
  int voteCount;
  List<Cast> crew;
  List<Cast> guestStars;

  Episode({
    required this.airDate,
    required this.episodeNumber,
    required this.episodeType,
    required this.id,
    required this.name,
    required this.overview,
    required this.productionCode,
    required this.runtime,
    required this.seasonNumber,
    required this.showId,
    required this.stillPath,
    required this.voteAverage,
    required this.voteCount,
    required this.crew,
    required this.guestStars,
  });

  String get unique => "$seasonNumber-$episodeNumber";

  factory Episode.fromMap(Map<String, dynamic> json) => Episode(
    airDate: json["air_date"] ?? "",
    episodeNumber: json["episode_number"] ?? 0,
    episodeType: json["episode_type"] ?? "",
    id: json["id"] ?? 0,
    name: json["name"] ?? "",
    overview: json["overview"] ?? "",
    productionCode: json["production_code"] ?? "",
    runtime: json["runtime"] ?? 0,
    seasonNumber: json["season_number"] ?? 0,
    showId: json["show_id"] ?? 0,
    stillPath: json["still_path"] ?? "",
    voteAverage: double.parse("${json["vote_average"] ?? 0}"),
    voteCount: json["vote_count"] ?? 0,
    crew: List<Cast>.from((json["crew"] ?? []).map((x) => Cast.fromMap(x))),
    guestStars: List<Cast>.from(
      (json["guest_stars"] ?? []).map((x) => Cast.fromMap(x)),
    ),
  );

  Map<String, dynamic> toMap() => {
    "air_date": airDate,
    "episode_number": episodeNumber,
    "episode_type": episodeType,
    "id": id,
    "name": name,
    "overview": overview,
    "production_code": productionCode,
    "runtime": runtime,
    "season_number": seasonNumber,
    "show_id": showId,
    "still_path": stillPath,
    "vote_average": voteAverage,
    "vote_count": voteCount,
    "crew": List<dynamic>.from(crew.map((x) => x.toMap())),
    "guest_stars": List<dynamic>.from(guestStars.map((x) => x.toMap())),
  };
}
