import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;

  /// Initialize the Supabase client using values from .env
  Future<void> initSupabase() async {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception(
        'Supabase URL or Anon Key not found in environment variables. '
        'Make sure SUPABASE_URL and SUPABASE_ANON_KEY are set in your .env file.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    _client = Supabase.instance.client;
  }

  /// Returns the Supabase client instance — must call [initSupabase] first
  SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'Supabase client not initialized. Call initSupabase() first.',
      );
    }
    return _client!;
  }

  // ──────────────────────────────────────────────
  //  Auth Methods
  // ──────────────────────────────────────────────

  /// Sign up a new user with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return client.auth.signUp(email: email, password: password);
  }

  /// Sign in an existing user with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign out the current user
  Future<void> signOut() async {
    return client.auth.signOut();
  }

  /// Get the currently authenticated user (null if not signed in)
  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  // ──────────────────────────────────────────────
  //  Watchlist Methods
  // ──────────────────────────────────────────────

  /// Add a movie to the user's watchlist
  Future<void> addToWatchlist({
    required String userId,
    required int movieId,
    required Map<String, dynamic> movieData,
  }) async {
    await client.from('watchlist').upsert({
      'user_id': userId,
      'movie_id': movieId,
      'movie_data': movieData,
    });
  }

  /// Remove a movie from the user's watchlist
  Future<void> removeFromWatchlist({
    required String userId,
    required int movieId,
  }) async {
    await client
        .from('watchlist')
        .delete()
        .eq('user_id', userId)
        .eq('movie_id', movieId);
  }

  /// Get the full watchlist for a user
  Future<List<Map<String, dynamic>>> getWatchlist(String userId) async {
    final response = await client
        .from('watchlist')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ──────────────────────────────────────────────
  //  Ratings Methods
  // ──────────────────────────────────────────────

  /// Rate a movie (or update an existing rating)
  Future<void> rateMovie({
    required String userId,
    required int movieId,
    required double rating,
  }) async {
    await client.from('ratings').upsert({
      'user_id': userId,
      'movie_id': movieId,
      'rating': rating,
    });
  }

  /// Get a user's rating for a specific movie (null if not rated)
  Future<double?> getUserRating({
    required String userId,
    required int movieId,
  }) async {
    final response = await client
        .from('ratings')
        .select('rating')
        .eq('user_id', userId)
        .eq('movie_id', movieId)
        .maybeSingle();

    if (response == null) return null;
    return (response['rating'] as num).toDouble();
  }

  /// Get all movies rated by a user (with their ratings)
  Future<List<Map<String, dynamic>>> getRatedMovies(String userId) async {
    final response = await client
        .from('ratings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ──────────────────────────────────────────────
  //  Favorites Methods
  // ──────────────────────────────────────────────

  /// Add a movie to the user's favorites
  Future<void> addToFavorites({
    required String userId,
    required int movieId,
    required Map<String, dynamic> movieData,
  }) async {
    await client.from('favorites').upsert({
      'user_id': userId,
      'movie_id': movieId,
      'movie_data': movieData,
    });
  }

  /// Remove a movie from the user's favorites
  Future<void> removeFromFavorites({
    required String userId,
    required int movieId,
  }) async {
    await client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('movie_id', movieId);
  }

  /// Get the full favorites list for a user
  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    final response = await client
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
