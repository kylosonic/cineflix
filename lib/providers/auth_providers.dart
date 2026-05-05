import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// Tracks whether the user is currently authenticated and who the user is.
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// StateNotifier that manages authentication state and exposes sign-in/up/out
/// actions to the UI layer.
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabaseService;

  AuthNotifier(this._supabaseService) : super(const AuthState()) {
    // Check if a user is already signed in on app start
    final currentUser = _supabaseService.getCurrentUser();
    if (currentUser != null) {
      state = AuthState(user: currentUser);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
      );
      state = AuthState(user: response.user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      state = AuthState(user: response.user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabaseService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh the current user from Supabase (useful after profile updates,
  /// or when the auth listener fires).
  void refreshUser() {
    final currentUser = _supabaseService.getCurrentUser();
    state = AuthState(user: currentUser);
  }
}

// ────────────────────────────────────────────────────────────
//  Providers
// ────────────────────────────────────────────────────────────

/// The Supabase service singleton provider.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// The main auth state provider — notifies listeners on sign-in/out.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AuthNotifier(supabaseService);
});

/// Convenience provider that exposes only the current [User] (or null).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});
