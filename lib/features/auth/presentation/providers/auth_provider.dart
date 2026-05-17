import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bondhu/services/supabase_service.dart';

// ── Raw stream provider (source of truth) ───────────────────────────────────

/// Emits every [AuthState] change from Supabase (sign-in, sign-out, token
/// refresh, password recovery, etc.).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.authState;
});

// ── Derived user provider (reactive) ────────────────────────────────────────

/// Always reflects the currently authenticated [User], or null when signed out.
/// Automatically updates whenever [authStateProvider] emits.
final currentUserProvider = Provider<User?>((ref) {
  // Derive from the stream so this rebuilds on every auth event.
  final asyncState = ref.watch(authStateProvider);
  return asyncState.valueOrNull?.session?.user;
});

/// Convenience: true when a user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// ── Session provider ─────────────────────────────────────────────────────────

/// Exposes the current [Session], or null when signed out.
final currentSessionProvider = Provider<Session?>((ref) {
  final asyncState = ref.watch(authStateProvider);
  return asyncState.valueOrNull?.session;
});

// ── Auth operation notifier ──────────────────────────────────────────────────

/// Tracks the loading / error state of auth operations (sign-in, sign-up,
/// password reset). UI layers watch this to drive loading indicators and error
/// banners without owning the async logic themselves.
///
/// State: null = idle, AuthOperationState wraps loading & error.
final authOperationProvider =
NotifierProvider<AuthOperationNotifier, AuthOperationState>(
  AuthOperationNotifier.new,
);

class AuthOperationState {
  const AuthOperationState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  AuthOperationState copyWith({bool? isLoading, String? error}) =>
      AuthOperationState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  bool get hasError => error != null;
}

class AuthOperationNotifier extends Notifier<AuthOperationState> {
  @override
  AuthOperationState build() => const AuthOperationState();

  void setLoading() => state = const AuthOperationState(isLoading: true);

  void setError(String msg) =>
      state = AuthOperationState(isLoading: false, error: msg);

  void reset() => state = const AuthOperationState();
}