// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Movie _$MovieFromJson(Map<String, dynamic> json) => Movie(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  overview: json['overview'] as String,
  posterPath: json['poster_path'] as String?,
  backdropPath: json['backdrop_path'] as String?,
  voteAverage: (json['vote_average'] as num).toDouble(),
  releaseDate: json['release_date'] as String?,
  genreIds: (json['genre_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$MovieToJson(Movie instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'overview': instance.overview,
  'poster_path': instance.posterPath,
  'backdrop_path': instance.backdropPath,
  'vote_average': instance.voteAverage,
  'release_date': instance.releaseDate,
  'genre_ids': instance.genreIds,
};

MovieDetail _$MovieDetailFromJson(Map<String, dynamic> json) => MovieDetail(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  overview: json['overview'] as String,
  posterPath: json['poster_path'] as String?,
  backdropPath: json['backdrop_path'] as String?,
  voteAverage: (json['vote_average'] as num).toDouble(),
  voteCount: (json['vote_count'] as num).toInt(),
  releaseDate: json['release_date'] as String?,
  runtime: (json['runtime'] as num?)?.toInt(),
  tagline: json['tagline'] as String?,
  status: json['status'] as String?,
  budget: (json['budget'] as num?)?.toInt(),
  revenue: (json['revenue'] as num?)?.toInt(),
  genres: (json['genres'] as List<dynamic>)
      .map((e) => Genre.fromJson(e as Map<String, dynamic>))
      .toList(),
  spokenLanguages: (json['spoken_languages'] as List<dynamic>)
      .map((e) => SpokenLanguage.fromJson(e as Map<String, dynamic>))
      .toList(),
  productionCompanies: (json['production_companies'] as List<dynamic>)
      .map((e) => ProductionCompany.fromJson(e as Map<String, dynamic>))
      .toList(),
  videos: json['videos'] == null
      ? null
      : Videos.fromJson(json['videos'] as Map<String, dynamic>),
  credits: json['credits'] == null
      ? null
      : Credits.fromJson(json['credits'] as Map<String, dynamic>),
  similar: json['similar'] == null
      ? null
      : SimilarMovies.fromJson(json['similar'] as Map<String, dynamic>),
  watchProviders: json['watch/providers'] == null
      ? null
      : WatchProviders.fromJson(
          json['watch/providers'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$MovieDetailToJson(MovieDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'overview': instance.overview,
      'poster_path': instance.posterPath,
      'backdrop_path': instance.backdropPath,
      'vote_average': instance.voteAverage,
      'vote_count': instance.voteCount,
      'release_date': instance.releaseDate,
      'runtime': instance.runtime,
      'tagline': instance.tagline,
      'status': instance.status,
      'budget': instance.budget,
      'revenue': instance.revenue,
      'genres': instance.genres,
      'spoken_languages': instance.spokenLanguages,
      'production_companies': instance.productionCompanies,
      'videos': instance.videos,
      'credits': instance.credits,
      'similar': instance.similar,
      'watch/providers': instance.watchProviders,
    };

Genre _$GenreFromJson(Map<String, dynamic> json) =>
    Genre(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$GenreToJson(Genre instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

SpokenLanguage _$SpokenLanguageFromJson(Map<String, dynamic> json) =>
    SpokenLanguage(
      iso: json['iso_639_1'] as String,
      englishName: json['english_name'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$SpokenLanguageToJson(SpokenLanguage instance) =>
    <String, dynamic>{
      'iso_639_1': instance.iso,
      'english_name': instance.englishName,
      'name': instance.name,
    };

ProductionCompany _$ProductionCompanyFromJson(Map<String, dynamic> json) =>
    ProductionCompany(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      logoPath: json['logo_path'] as String?,
      originCountry: json['origin_country'] as String,
    );

Map<String, dynamic> _$ProductionCompanyToJson(ProductionCompany instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logo_path': instance.logoPath,
      'origin_country': instance.originCountry,
    };

Videos _$VideosFromJson(Map<String, dynamic> json) => Videos(
  results: (json['results'] as List<dynamic>)
      .map((e) => Video.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$VideosToJson(Videos instance) => <String, dynamic>{
  'results': instance.results,
};

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
  id: json['id'] as String,
  key: json['key'] as String,
  name: json['name'] as String,
  site: json['site'] as String,
  type: json['type'] as String,
  official: json['official'] as bool,
);

Map<String, dynamic> _$VideoToJson(Video instance) => <String, dynamic>{
  'id': instance.id,
  'key': instance.key,
  'name': instance.name,
  'site': instance.site,
  'type': instance.type,
  'official': instance.official,
};

Credits _$CreditsFromJson(Map<String, dynamic> json) => Credits(
  cast: (json['cast'] as List<dynamic>)
      .map((e) => CastMember.fromJson(e as Map<String, dynamic>))
      .toList(),
  crew: (json['crew'] as List<dynamic>)
      .map((e) => CrewMember.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CreditsToJson(Credits instance) => <String, dynamic>{
  'cast': instance.cast,
  'crew': instance.crew,
};

CastMember _$CastMemberFromJson(Map<String, dynamic> json) => CastMember(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  character: json['character'] as String,
  profilePath: json['profile_path'] as String?,
  order: (json['order'] as num).toInt(),
);

Map<String, dynamic> _$CastMemberToJson(CastMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'character': instance.character,
      'profile_path': instance.profilePath,
      'order': instance.order,
    };

CrewMember _$CrewMemberFromJson(Map<String, dynamic> json) => CrewMember(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  job: json['job'] as String,
  department: json['department'] as String,
  profilePath: json['profile_path'] as String?,
);

Map<String, dynamic> _$CrewMemberToJson(CrewMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'job': instance.job,
      'department': instance.department,
      'profile_path': instance.profilePath,
    };

SimilarMovies _$SimilarMoviesFromJson(Map<String, dynamic> json) =>
    SimilarMovies(
      results: (json['results'] as List<dynamic>)
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SimilarMoviesToJson(SimilarMovies instance) =>
    <String, dynamic>{'results': instance.results};

WatchProviders _$WatchProvidersFromJson(Map<String, dynamic> json) =>
    WatchProviders(
      results: (json['results'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, CountryProviders.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$WatchProvidersToJson(WatchProviders instance) =>
    <String, dynamic>{'results': instance.results};

CountryProviders _$CountryProvidersFromJson(Map<String, dynamic> json) =>
    CountryProviders(
      link: json['link'] as String?,
      flatrate: (json['flatrate'] as List<dynamic>?)
          ?.map((e) => ProviderInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      rent: (json['rent'] as List<dynamic>?)
          ?.map((e) => ProviderInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      buy: (json['buy'] as List<dynamic>?)
          ?.map((e) => ProviderInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CountryProvidersToJson(CountryProviders instance) =>
    <String, dynamic>{
      'link': instance.link,
      'flatrate': instance.flatrate,
      'rent': instance.rent,
      'buy': instance.buy,
    };

ProviderInfo _$ProviderInfoFromJson(Map<String, dynamic> json) => ProviderInfo(
  providerId: (json['provider_id'] as num).toInt(),
  providerName: json['provider_name'] as String,
  logoPath: json['logo_path'] as String,
  displayPriority: (json['display_priority'] as num).toInt(),
);

Map<String, dynamic> _$ProviderInfoToJson(ProviderInfo instance) =>
    <String, dynamic>{
      'provider_id': instance.providerId,
      'provider_name': instance.providerName,
      'logo_path': instance.logoPath,
      'display_priority': instance.displayPriority,
    };
