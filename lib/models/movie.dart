import 'package:json_annotation/json_annotation.dart';
import 'package:cineflix/config/app_config.dart';

part 'movie.g.dart';

@JsonSerializable()
class Movie {
  final int id;
  final String title;
  final String overview;

  @JsonKey(name: 'poster_path')
  final String? posterPath;

  @JsonKey(name: 'backdrop_path')
  final String? backdropPath;

  @JsonKey(name: 'vote_average')
  final double voteAverage;

  @JsonKey(name: 'release_date')
  final String? releaseDate;

  @JsonKey(name: 'genre_ids')
  final List<int> genreIds;

  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.releaseDate,
    required this.genreIds,
  });

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);

  Map<String, dynamic> toJson() => _$MovieToJson(this);

  String? get posterUrl {
    if (posterPath == null) return null;
    return '${AppConfig.tmdbImageBaseUrl}/w500$posterPath';
  }

  String? get backdropUrl {
    if (backdropPath == null) return null;
    return '${AppConfig.tmdbImageBaseUrl}/w1280$backdropPath';
  }
}

@JsonSerializable()
class MovieDetail {
  final int id;
  final String title;
  final String overview;

  @JsonKey(name: 'poster_path')
  final String? posterPath;

  @JsonKey(name: 'backdrop_path')
  final String? backdropPath;

  @JsonKey(name: 'vote_average')
  final double voteAverage;

  @JsonKey(name: 'vote_count')
  final int voteCount;

  @JsonKey(name: 'release_date')
  final String? releaseDate;

  final int? runtime;
  final String? tagline;
  final String? status;
  final int? budget;
  final int? revenue;

  final List<Genre> genres;

  @JsonKey(name: 'spoken_languages')
  final List<SpokenLanguage> spokenLanguages;

  @JsonKey(name: 'production_companies')
  final List<ProductionCompany> productionCompanies;

  final Videos? videos;
  final Credits? credits;
  final SimilarMovies? similar;

  @JsonKey(name: 'watch/providers')
  final WatchProviders? watchProviders;

  const MovieDetail({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    this.releaseDate,
    this.runtime,
    this.tagline,
    this.status,
    this.budget,
    this.revenue,
    required this.genres,
    required this.spokenLanguages,
    required this.productionCompanies,
    this.videos,
    this.credits,
    this.similar,
    this.watchProviders,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) =>
      _$MovieDetailFromJson(json);

  Map<String, dynamic> toJson() => _$MovieDetailToJson(this);

  String? get posterUrl {
    if (posterPath == null) return null;
    return '${AppConfig.tmdbImageBaseUrl}/w500$posterPath';
  }

  String? get backdropUrl {
    if (backdropPath == null) return null;
    return '${AppConfig.tmdbImageBaseUrl}/w1280$backdropPath';
  }
}

@JsonSerializable()
class Genre {
  final int id;
  final String name;

  const Genre({
    required this.id,
    required this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);

  Map<String, dynamic> toJson() => _$GenreToJson(this);
}

@JsonSerializable()
class SpokenLanguage {
  @JsonKey(name: 'iso_639_1')
  final String iso;
  @JsonKey(name: 'english_name')
  final String englishName;
  final String name;

  const SpokenLanguage({
    required this.iso,
    required this.englishName,
    required this.name,
  });

  factory SpokenLanguage.fromJson(Map<String, dynamic> json) =>
      _$SpokenLanguageFromJson(json);

  Map<String, dynamic> toJson() => _$SpokenLanguageToJson(this);
}

@JsonSerializable()
class ProductionCompany {
  final int id;
  final String name;

  @JsonKey(name: 'logo_path')
  final String? logoPath;

  @JsonKey(name: 'origin_country')
  final String originCountry;

  const ProductionCompany({
    required this.id,
    required this.name,
    this.logoPath,
    required this.originCountry,
  });

  factory ProductionCompany.fromJson(Map<String, dynamic> json) =>
      _$ProductionCompanyFromJson(json);

  Map<String, dynamic> toJson() => _$ProductionCompanyToJson(this);
}

@JsonSerializable()
class Videos {
  final List<Video> results;

  const Videos({required this.results});

  factory Videos.fromJson(Map<String, dynamic> json) =>
      _$VideosFromJson(json);

  Map<String, dynamic> toJson() => _$VideosToJson(this);
}

@JsonSerializable()
class Video {
  final String id;
  final String key;
  final String name;
  final String site;
  final String type;

  @JsonKey(name: 'official')
  final bool official;

  const Video({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.type,
    required this.official,
  });

  factory Video.fromJson(Map<String, dynamic> json) =>
      _$VideoFromJson(json);

  Map<String, dynamic> toJson() => _$VideoToJson(this);
}

@JsonSerializable()
class Credits {
  final List<CastMember> cast;
  final List<CrewMember> crew;

  const Credits({required this.cast, required this.crew});

  factory Credits.fromJson(Map<String, dynamic> json) =>
      _$CreditsFromJson(json);

  Map<String, dynamic> toJson() => _$CreditsToJson(this);
}

@JsonSerializable()
class CastMember {
  final int id;
  final String name;
  final String character;

  @JsonKey(name: 'profile_path')
  final String? profilePath;

  final int order;

  const CastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
    required this.order,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) =>
      _$CastMemberFromJson(json);

  Map<String, dynamic> toJson() => _$CastMemberToJson(this);

  String? get profileUrl {
    if (profilePath == null) return null;
    return '${AppConfig.tmdbImageBaseUrl}/w185$profilePath';
  }
}

@JsonSerializable()
class CrewMember {
  final int id;
  final String name;
  final String job;
  final String department;

  @JsonKey(name: 'profile_path')
  final String? profilePath;

  const CrewMember({
    required this.id,
    required this.name,
    required this.job,
    required this.department,
    this.profilePath,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) =>
      _$CrewMemberFromJson(json);

  Map<String, dynamic> toJson() => _$CrewMemberToJson(this);
}

@JsonSerializable()
class SimilarMovies {
  final List<Movie> results;

  const SimilarMovies({required this.results});

  factory SimilarMovies.fromJson(Map<String, dynamic> json) =>
      _$SimilarMoviesFromJson(json);

  Map<String, dynamic> toJson() => _$SimilarMoviesToJson(this);
}

@JsonSerializable()
class WatchProviders {
  final Map<String, CountryProviders>? results;

  const WatchProviders({this.results});

  factory WatchProviders.fromJson(Map<String, dynamic> json) =>
      _$WatchProvidersFromJson(json);

  Map<String, dynamic> toJson() => _$WatchProvidersToJson(this);
}

@JsonSerializable()
class CountryProviders {
  final String? link;

  @JsonKey(name: 'flatrate')
  final List<ProviderInfo>? flatrate;

  @JsonKey(name: 'rent')
  final List<ProviderInfo>? rent;

  @JsonKey(name: 'buy')
  final List<ProviderInfo>? buy;

  const CountryProviders({
    this.link,
    this.flatrate,
    this.rent,
    this.buy,
  });

  factory CountryProviders.fromJson(Map<String, dynamic> json) =>
      _$CountryProvidersFromJson(json);

  Map<String, dynamic> toJson() => _$CountryProvidersToJson(this);
}

@JsonSerializable()
class ProviderInfo {
  @JsonKey(name: 'provider_id')
  final int providerId;

  @JsonKey(name: 'provider_name')
  final String providerName;

  @JsonKey(name: 'logo_path')
  final String logoPath;

  @JsonKey(name: 'display_priority')
  final int displayPriority;

  const ProviderInfo({
    required this.providerId,
    required this.providerName,
    required this.logoPath,
    required this.displayPriority,
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) =>
      _$ProviderInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderInfoToJson(this);
}
