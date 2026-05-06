import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:cineflix/config/app_config.dart';
import 'package:cineflix/models/movie.dart';

class TmdbService {
  late final Dio _dio;
  final String _apiKey;
  final Map<String, _CacheEntry<dynamic>> _responseCache = {};
  final Map<String, Future<dynamic>> _inFlightRequests = {};

  static const Duration _shortCache = Duration(minutes: 3);
  static const Duration _standardCache = Duration(minutes: 8);
  static const Duration _detailCache = Duration(minutes: 12);

  TmdbService() : _apiKey = AppConfig.tmdbApiKey.trim() {
    final isV4Token = _apiKey.startsWith('eyJ'); // JWT token = v4 auth

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.tmdbBaseUrl,
        connectTimeout: const Duration(seconds: 7),
        receiveTimeout: const Duration(seconds: 9),
        sendTimeout: const Duration(seconds: 7),
        responseType: ResponseType.json,
        headers: const {'Accept': 'application/json'},
      ),
    );

    if (isV4Token) {
      _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
    }

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }
  }

  void _ensureConfigured() {
    if (_apiKey.isNotEmpty) return;
    throw Exception(
      'TMDB_API_KEY is missing. Add it to your environment and redeploy.',
    );
  }

  String _cacheKey(String path, [Map<String, dynamic>? params]) {
    if (params == null || params.isEmpty) return path;
    final entries = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final normalized = entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    return '$path?$normalized';
  }

  Future<T> _withCache<T>({
    required String key,
    required Duration ttl,
    required Future<T> Function() load,
  }) async {
    final now = DateTime.now();
    final cached = _responseCache[key];
    if (cached != null && cached.expiresAt.isAfter(now)) {
      return cached.value as T;
    }

    final inFlight = _inFlightRequests[key];
    if (inFlight != null) return inFlight as Future<T>;

    final future = load();
    _inFlightRequests[key] = future;

    try {
      final value = await future;
      _responseCache[key] = _CacheEntry<dynamic>(
        value: value,
        expiresAt: now.add(ttl),
      );
      return value;
    } finally {
      _inFlightRequests.remove(key);
    }
  }

  Future<Response<Map<String, dynamic>>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    _ensureConfigured();

    final merged = <String, dynamic>{
      ...(queryParameters ?? const <String, dynamic>{}),
    };

    if (!_apiKey.startsWith('eyJ')) {
      merged['api_key'] = _apiKey;
    }

    return _dio.get<Map<String, dynamic>>(path, queryParameters: merged);
  }

  /// Parse paginated results from TMDB responses into a list of movies
  /// plus metadata.
  PaginatedMovies _parseMovieResponse(Response<Map<String, dynamic>> response) {
    final data = response.data!;
    final List<dynamic> results = data['results'] ?? [];
    final movies = results
        .map((json) => Movie.fromJson(json as Map<String, dynamic>))
        .toList();

    return PaginatedMovies(
      movies: movies,
      page: data['page'] ?? 1,
      totalPages: data['total_pages'] ?? 1,
      totalResults: data['total_results'] ?? 0,
    );
  }

  /// GET /trending/movie/week
  Future<PaginatedMovies> getTrending() async {
    const path = '/trending/movie/week';
    try {
      return _withCache(
        key: _cacheKey(path),
        ttl: _shortCache,
        load: () async {
          final response = await _get(path);
          return _parseMovieResponse(response);
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /movie/popular
  Future<PaginatedMovies> getPopular({int page = 1}) async {
    const path = '/movie/popular';
    final params = {'page': page};
    try {
      return _withCache(
        key: _cacheKey(path, params),
        ttl: _standardCache,
        load: () async {
          final response = await _get(path, queryParameters: params);
          return _parseMovieResponse(response);
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /movie/top_rated
  Future<PaginatedMovies> getTopRated({int page = 1}) async {
    const path = '/movie/top_rated';
    final params = {'page': page};
    try {
      return _withCache(
        key: _cacheKey(path, params),
        ttl: _standardCache,
        load: () async {
          final response = await _get(path, queryParameters: params);
          return _parseMovieResponse(response);
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /movie/now_playing
  Future<PaginatedMovies> getNowPlaying({int page = 1}) async {
    const path = '/movie/now_playing';
    final params = {'page': page};
    try {
      return _withCache(
        key: _cacheKey(path, params),
        ttl: _shortCache,
        load: () async {
          final response = await _get(path, queryParameters: params);
          return _parseMovieResponse(response);
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /search/movie
  Future<PaginatedMovies> searchMovies(String query, {int page = 1}) async {
    const path = '/search/movie';
    final params = {'query': query, 'page': page};

    try {
      return _withCache(
        key: _cacheKey(path, params),
        ttl: _shortCache,
        load: () async {
          final response = await _get(path, queryParameters: params);
          return _parseMovieResponse(response);
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /movie/{id}?append_to_response=videos,credits,similar,watch/providers
  Future<MovieDetail> getMovieDetails(int movieId) async {
    final path = '/movie/$movieId';
    final params = {
      'append_to_response': 'videos,credits,similar,watch/providers',
    };

    try {
      return _withCache(
        key: _cacheKey(path, params),
        ttl: _detailCache,
        load: () async {
          final response = await _get(path, queryParameters: params);
          return MovieDetail.fromJson(response.data!);
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /genre/movie/list
  Future<List<Genre>> getGenres() async {
    const path = '/genre/movie/list';
    try {
      return _withCache(
        key: _cacheKey(path),
        ttl: const Duration(hours: 12),
        load: () async {
          final response = await _get(path);
          final List<dynamic> genresJson = response.data!['genres'] ?? [];
          return genresJson
              .map((json) => Genre.fromJson(json as Map<String, dynamic>))
              .toList();
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /discover/movie?with_genres={genreId}
  Future<PaginatedMovies> discoverByGenre(int genreId, {int page = 1}) async {
    const path = '/discover/movie';
    final params = {'with_genres': genreId, 'page': page};

    try {
      return _withCache(
        key: _cacheKey(path, params),
        ttl: _standardCache,
        load: () async {
          final response = await _get(path, queryParameters: params);
          return _parseMovieResponse(response);
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    String message = 'Something went wrong';
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final statusMessage = e.response?.statusMessage;
      message = 'TMDB API error: $statusCode $statusMessage';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timed out. Please check your internet connection.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Server took too long to respond. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Unable to connect. Please check your internet connection.';
    }
    return Exception(message);
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  const _CacheEntry({required this.value, required this.expiresAt});
}

/// Wraps a page of movies with pagination metadata.
class PaginatedMovies {
  final List<Movie> movies;
  final int page;
  final int totalPages;
  final int totalResults;

  const PaginatedMovies({
    required this.movies,
    required this.page,
    required this.totalPages,
    required this.totalResults,
  });

  bool get hasNextPage => page < totalPages;
}
