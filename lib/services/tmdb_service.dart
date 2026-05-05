import 'package:dio/dio.dart';
import 'package:cineflix/config/app_config.dart';
import 'package:cineflix/models/movie.dart';

class TmdbService {
  late final Dio _dio;

  TmdbService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.tmdbBaseUrl,
      queryParameters: {
        'api_key': AppConfig.tmdbApiKey,
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
    ));
  }

  /// Parse paginated results from TMDB responses into a list of Movies
  /// plus metadata.
  Future<PaginatedMovies> _parseMovieResponse(
      Response<Map<String, dynamic>> response) async {
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
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/trending/movie/week',
      );
      return _parseMovieResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /movie/popular
  Future<PaginatedMovies> getPopular({int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/movie/popular',
        queryParameters: {'page': page},
      );
      return _parseMovieResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /movie/top_rated
  Future<PaginatedMovies> getTopRated({int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/movie/top_rated',
        queryParameters: {'page': page},
      );
      return _parseMovieResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /movie/now_playing
  Future<PaginatedMovies> getNowPlaying({int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/movie/now_playing',
        queryParameters: {'page': page},
      );
      return _parseMovieResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /search/movie
  Future<PaginatedMovies> searchMovies(String query, {int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/search/movie',
        queryParameters: {
          'query': query,
          'page': page,
        },
      );
      return _parseMovieResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /movie/{id}?append_to_response=videos,credits,similar,watch/providers
  Future<MovieDetail> getMovieDetails(int movieId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/movie/$movieId',
        queryParameters: {
          'append_to_response': 'videos,credits,similar,watch/providers',
        },
      );
      return MovieDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /genre/movie/list
  Future<List<Genre>> getGenres() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/genre/movie/list',
      );
      final List<dynamic> genresJson = response.data!['genres'] ?? [];
      return genresJson
          .map((json) => Genre.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /discover/movie?with_genres={genreId}
  Future<PaginatedMovies> discoverByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/discover/movie',
        queryParameters: {
          'with_genres': genreId,
          'page': page,
        },
      );
      return _parseMovieResponse(response);
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
      message =
          'Unable to connect. Please check your internet connection.';
    }
    return Exception(message);
  }
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
