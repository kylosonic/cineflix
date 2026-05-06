import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/supabase_service.dart';
import 'auth_providers.dart';

// ────────────────────────────────────────────────────────────
//  TMDB Service Provider
// ────────────────────────────────────────────────────────────

final tmdbServiceProvider = Provider<TmdbService>((ref) {
  return TmdbService();
});

enum MovieFeedType { trending, topRated, nowPlaying, popular }

class PagedMovieCollectionState {
  final List<Movie> movies;
  final int page;
  final bool hasNextPage;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? error;

  const PagedMovieCollectionState({
    this.movies = const [],
    this.page = 0,
    this.hasNextPage = true,
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.error,
  });

  factory PagedMovieCollectionState.initial({bool hasNextPage = true}) {
    return PagedMovieCollectionState(hasNextPage: hasNextPage);
  }

  PagedMovieCollectionState copyWith({
    List<Movie>? movies,
    int? page,
    bool? hasNextPage,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return PagedMovieCollectionState(
      movies: movies ?? this.movies,
      page: page ?? this.page,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

List<Movie> _mergeUniqueMovies(List<Movie> existing, List<Movie> incoming) {
  final byId = <int, Movie>{for (final movie in existing) movie.id: movie};
  for (final movie in incoming) {
    byId[movie.id] = movie;
  }
  return byId.values.toList(growable: false);
}

class PagedMoviesNotifier extends StateNotifier<PagedMovieCollectionState> {
  final TmdbService _tmdbService;
  final MovieFeedType _feedType;

  PagedMoviesNotifier(this._tmdbService, this._feedType)
    : super(PagedMovieCollectionState.initial()) {
    loadInitial();
  }

  Future<PaginatedMovies> _fetchPage(int page) {
    return switch (_feedType) {
      MovieFeedType.trending => _tmdbService.getTrending(page: page),
      MovieFeedType.topRated => _tmdbService.getTopRated(page: page),
      MovieFeedType.nowPlaying => _tmdbService.getNowPlaying(page: page),
      MovieFeedType.popular => _tmdbService.getPopular(page: page),
    };
  }

  Future<void> loadInitial() async {
    if (state.page > 0 || state.isLoadingInitial) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (state.isLoadingInitial) return;
    state = state.copyWith(isLoadingInitial: true, clearError: true);

    try {
      final page = await _fetchPage(1);
      state = state.copyWith(
        movies: page.movies,
        page: page.page,
        hasNextPage: page.hasNextPage,
        isLoadingInitial: false,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingInitial: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingInitial || state.isLoadingMore || !state.hasNextPage) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);

    final nextPage = state.page + 1;
    try {
      final page = await _fetchPage(nextPage);
      state = state.copyWith(
        movies: _mergeUniqueMovies(state.movies, page.movies),
        page: page.page,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final pagedMoviesProvider =
    StateNotifierProvider.family<
      PagedMoviesNotifier,
      PagedMovieCollectionState,
      MovieFeedType
    >((ref, feedType) {
      final tmdbService = ref.watch(tmdbServiceProvider);
      return PagedMoviesNotifier(tmdbService, feedType);
    });

class PagedSearchMoviesNotifier
    extends StateNotifier<PagedMovieCollectionState> {
  final TmdbService _tmdbService;
  final String _query;

  PagedSearchMoviesNotifier(this._tmdbService, this._query)
    : super(
        _query.trim().isEmpty
            ? PagedMovieCollectionState.initial(hasNextPage: false)
            : PagedMovieCollectionState.initial(),
      ) {
    if (_query.trim().isNotEmpty) {
      loadInitial();
    }
  }

  Future<void> loadInitial() async {
    if (_query.trim().isEmpty || state.page > 0 || state.isLoadingInitial) {
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (_query.trim().isEmpty || state.isLoadingInitial) return;

    state = state.copyWith(isLoadingInitial: true, clearError: true);
    try {
      final page = await _tmdbService.searchMovies(_query, page: 1);
      state = state.copyWith(
        movies: page.movies,
        page: page.page,
        hasNextPage: page.hasNextPage,
        isLoadingInitial: false,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingInitial: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (_query.trim().isEmpty ||
        state.isLoadingInitial ||
        state.isLoadingMore ||
        !state.hasNextPage) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.page + 1;
    try {
      final page = await _tmdbService.searchMovies(_query, page: nextPage);
      state = state.copyWith(
        movies: _mergeUniqueMovies(state.movies, page.movies),
        page: page.page,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final pagedSearchMoviesProvider = StateNotifierProvider.autoDispose
    .family<PagedSearchMoviesNotifier, PagedMovieCollectionState, String>((
      ref,
      query,
    ) {
      final tmdbService = ref.watch(tmdbServiceProvider);
      return PagedSearchMoviesNotifier(tmdbService, query);
    });

class PagedGenreMoviesNotifier
    extends StateNotifier<PagedMovieCollectionState> {
  final TmdbService _tmdbService;
  final int _genreId;

  PagedGenreMoviesNotifier(this._tmdbService, this._genreId)
    : super(PagedMovieCollectionState.initial()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.page > 0 || state.isLoadingInitial) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (state.isLoadingInitial) return;
    state = state.copyWith(isLoadingInitial: true, clearError: true);

    try {
      final page = await _tmdbService.discoverByGenre(_genreId, page: 1);
      state = state.copyWith(
        movies: page.movies,
        page: page.page,
        hasNextPage: page.hasNextPage,
        isLoadingInitial: false,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingInitial: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingInitial || state.isLoadingMore || !state.hasNextPage) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.page + 1;
    try {
      final page = await _tmdbService.discoverByGenre(_genreId, page: nextPage);
      state = state.copyWith(
        movies: _mergeUniqueMovies(state.movies, page.movies),
        page: page.page,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final pagedGenreMoviesProvider = StateNotifierProvider.autoDispose
    .family<PagedGenreMoviesNotifier, PagedMovieCollectionState, int>((
      ref,
      genreId,
    ) {
      final tmdbService = ref.watch(tmdbServiceProvider);
      return PagedGenreMoviesNotifier(tmdbService, genreId);
    });

// ────────────────────────────────────────────────────────────
//  Movie List Providers
// ────────────────────────────────────────────────────────────

/// Fetches trending movies for the current day/week.
final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return (await tmdbService.getTrending()).movies;
});

/// Fetches popular movies with pagination support.
/// Pass the page number via the family argument.
final popularMoviesProvider = FutureProvider.family<List<Movie>, int>((
  ref,
  page,
) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return (await tmdbService.getPopular(page: page)).movies;
});

/// Fetches top-rated movies with pagination support.
final topRatedMoviesProvider = FutureProvider.family<List<Movie>, int>((
  ref,
  page,
) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return (await tmdbService.getTopRated(page: page)).movies;
});

/// Fetches movies currently playing in theatres with pagination.
final nowPlayingMoviesProvider = FutureProvider.family<List<Movie>, int>((
  ref,
  page,
) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return (await tmdbService.getNowPlaying(page: page)).movies;
});

/// Searches for movies by a query string.
final searchResultsProvider = FutureProvider.family<List<Movie>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return [];
  final tmdbService = ref.watch(tmdbServiceProvider);
  return (await tmdbService.searchMovies(query)).movies;
});

// ────────────────────────────────────────────────────────────
//  Movie Detail & Genres Providers
// ────────────────────────────────────────────────────────────

/// Fetches detailed information for a single movie by its TMDB id.
final movieDetailProvider = FutureProvider.family<MovieDetail, int>((
  ref,
  movieId,
) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return tmdbService.getMovieDetails(movieId);
});

/// Fetches the full genre list from TMDB.
final genresProvider = FutureProvider<List<Genre>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return tmdbService.getGenres();
});

/// Discovers movies by genre id.
final discoverByGenreProvider = FutureProvider.family<List<Movie>, int>((
  ref,
  genreId,
) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  final result = await tmdbService.discoverByGenre(genreId);
  return result.movies;
});

// ────────────────────────────────────────────────────────────
//  Watchlist State & Provider
// ────────────────────────────────────────────────────────────

class WatchlistState {
  final List<Map<String, dynamic>> movies;
  final bool isLoading;
  final String? error;

  const WatchlistState({
    this.movies = const [],
    this.isLoading = false,
    this.error,
  });
}

class WatchlistNotifier extends StateNotifier<WatchlistState> {
  final SupabaseService _supabaseService;
  final Ref _ref;

  WatchlistNotifier(this._supabaseService, this._ref)
    : super(const WatchlistState());

  /// Load the watchlist from Supabase for the currently signed-in user.
  Future<void> loadWatchlist() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const WatchlistState(isLoading: true);
    try {
      final movies = await _supabaseService.getWatchlist(user.id);
      state = WatchlistState(movies: movies);
    } catch (e) {
      state = WatchlistState(error: e.toString());
    }
  }

  /// Add a movie to the watchlist and refresh the local list.
  Future<void> addToWatchlist({
    required int movieId,
    required Map<String, dynamic> movieData,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await _supabaseService.addToWatchlist(
        userId: user.id,
        movieId: movieId,
        movieData: movieData,
      );
      await loadWatchlist();
    } catch (e) {
      state = WatchlistState(movies: state.movies, error: e.toString());
    }
  }

  /// Remove a movie from the watchlist and refresh.
  Future<void> removeFromWatchlist(int movieId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await _supabaseService.removeFromWatchlist(
        userId: user.id,
        movieId: movieId,
      );
      await loadWatchlist();
    } catch (e) {
      state = WatchlistState(movies: state.movies, error: e.toString());
    }
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, WatchlistState>((ref) {
      final supabaseService = ref.watch(supabaseServiceProvider);
      return WatchlistNotifier(supabaseService, ref);
    });

// ────────────────────────────────────────────────────────────
//  Favorites State & Provider
// ────────────────────────────────────────────────────────────

class FavoritesState {
  final List<Map<String, dynamic>> movies;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.movies = const [],
    this.isLoading = false,
    this.error,
  });
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final SupabaseService _supabaseService;
  final Ref _ref;

  FavoritesNotifier(this._supabaseService, this._ref)
    : super(const FavoritesState());

  Future<void> loadFavorites() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const FavoritesState(isLoading: true);
    try {
      final movies = await _supabaseService.getFavorites(user.id);
      state = FavoritesState(movies: movies);
    } catch (e) {
      state = FavoritesState(error: e.toString());
    }
  }

  Future<void> addToFavorites({
    required int movieId,
    required Map<String, dynamic> movieData,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await _supabaseService.addToFavorites(
        userId: user.id,
        movieId: movieId,
        movieData: movieData,
      );
      await loadFavorites();
    } catch (e) {
      state = FavoritesState(movies: state.movies, error: e.toString());
    }
  }

  Future<void> removeFromFavorites(int movieId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await _supabaseService.removeFromFavorites(
        userId: user.id,
        movieId: movieId,
      );
      await loadFavorites();
    } catch (e) {
      state = FavoritesState(movies: state.movies, error: e.toString());
    }
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
      final supabaseService = ref.watch(supabaseServiceProvider);
      return FavoritesNotifier(supabaseService, ref);
    });

// ────────────────────────────────────────────────────────────
//  Ratings State & Provider
// ────────────────────────────────────────────────────────────

class RatingsState {
  final Map<int, double> ratings; // movieId -> rating
  final List<Map<String, dynamic>> ratedMovies;
  final bool isLoading;
  final String? error;

  const RatingsState({
    this.ratings = const {},
    this.ratedMovies = const [],
    this.isLoading = false,
    this.error,
  });
}

class RatingsNotifier extends StateNotifier<RatingsState> {
  final SupabaseService _supabaseService;
  final Ref _ref;

  RatingsNotifier(this._supabaseService, this._ref)
    : super(const RatingsState());

  Future<void> loadRatedMovies() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const RatingsState(isLoading: true);
    try {
      final movies = await _supabaseService.getRatedMovies(user.id);
      final ratingsMap = <int, double>{};
      for (final m in movies) {
        ratingsMap[m['movie_id'] as int] = (m['rating'] as num).toDouble();
      }
      state = RatingsState(ratings: ratingsMap, ratedMovies: movies);
    } catch (e) {
      state = RatingsState(error: e.toString());
    }
  }

  Future<void> rateMovie({required int movieId, required double rating}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await _supabaseService.rateMovie(
        userId: user.id,
        movieId: movieId,
        rating: rating,
      );
      await loadRatedMovies();
    } catch (e) {
      state = RatingsState(
        ratings: state.ratings,
        ratedMovies: state.ratedMovies,
        error: e.toString(),
      );
    }
  }

  Future<double?> getUserRating(int movieId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return null;

    try {
      return await _supabaseService.getUserRating(
        userId: user.id,
        movieId: movieId,
      );
    } catch (_) {
      return null;
    }
  }
}

final ratingsProvider = StateNotifierProvider<RatingsNotifier, RatingsState>((
  ref,
) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return RatingsNotifier(supabaseService, ref);
});
