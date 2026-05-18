import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bondhu/services/supabase_auth_service.dart';
import 'package:bondhu/services/supabase_reaction_service.dart';

class SupabaseService {
  SupabaseService._();

  // ── Core Client ──────────────────────────────────────────────────────────
  static final SupabaseClient client = Supabase.instance.client;

  // ── Sub-Services (Lazy Initialized) ──────────────────────────────────────
  // We use lazy initialization so they aren't created in memory until called.
  static SupabaseAuthService? _authService;
  static SupabaseReactionService? _reactionService;

  static SupabaseAuthService get auth {
    _authService ??= SupabaseAuthService(client);
    return _authService!;
  }

  static SupabaseReactionService get reactions {
    _reactionService ??= SupabaseReactionService(client);
    return _reactionService!;
  }

// ── Future Expansion ─────────────────────────────────────────────────────
// static SupabasePostService? _postService;
// static SupabasePostService get posts {
//   _postService ??= SupabasePostService(client);
//   return _postService!;
// }
}