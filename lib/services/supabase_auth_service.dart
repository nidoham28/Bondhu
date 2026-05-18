import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _client;

  // Pass the client via constructor
  SupabaseAuthService(this._client);

  // ── Getters ─────────────────────────────────────────────────────────────
  Stream<AuthState> get authState => _client.auth.onAuthStateChange;
  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  // ── Auth operations ───────────────────────────────────────────────────────

  /// Signs in with [email] and [password].
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Creates a new account with [email] and [password].
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  /// Sends a password-reset email to [email].
  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Updates the password of the currently authenticated user.
  Future<UserResponse> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Signs the current user out and clears the local session.
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  /// Refreshes the current session. Returns null if no session exists.
  Future<AuthResponse?> refreshSession() async {
    final session = currentSession;
    if (session == null) return null;
    return _client.auth.refreshSession();
  }
}