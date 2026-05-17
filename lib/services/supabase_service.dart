import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseClient client = Supabase.instance.client;

  static Stream<AuthState> get authState => client.auth.onAuthStateChange;
  static Session? get currentSession => client.auth.currentSession;
  static User? get currentUser => client.auth.currentUser;

  // ── Auth operations ───────────────────────────────────────────────────────

  /// Signs in with [email] and [password].
  /// Throws [AuthException] on failure so callers can map errors.
  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Creates a new account with [email] and [password].
  /// Supabase sends a confirmation email automatically when email-confirm is
  /// enabled in the project settings (recommended for production).
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  /// Sends a password-reset email to [email].
  static Future<void> sendPasswordResetEmail(String email) {
    return client.auth.resetPasswordForEmail(email.trim());
  }

  /// Updates the password of the currently authenticated user.
  static Future<UserResponse> updatePassword(String newPassword) {
    return client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Signs the current user out and clears the local session.
  static Future<void> signOut() {
    return client.auth.signOut();
  }

  /// Refreshes the current session. Returns null if no session exists.
  static Future<AuthResponse?> refreshSession() async {
    final session = currentSession;
    if (session == null) return null;
    return client.auth.refreshSession();
  }
}