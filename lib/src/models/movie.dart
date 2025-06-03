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
  };
}
