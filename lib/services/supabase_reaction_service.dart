import 'package:bondhu/features/reactions/models/reaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseReactionService {
  final SupabaseClient _client;

  SupabaseReactionService(this._client);

  // ── Reaction Operations ───────────────────────────────────────────────────

  /// Toggles a reaction on a post.
  /// If [reactionType] matches existing, it un-reacts.
  /// If different, it changes the reaction.
  /// If none exists, it creates a new reaction.
  Future<PostReactionState> toggleReaction({
    required String postId,
    required String reactionType,
  }) async {
    try {
      final response = await _client.rpc(
        'toggle_post_reaction',
        params: {
          'p_post_id': postId,
          'p_reaction_type': reactionType,
        },
      );

      return PostReactionState.fromMap(response);
    } catch (e) {
      print('Error toggling reaction: $e');
      rethrow;
    }
  }

  /// Fetches reaction states for multiple posts (e.g., for a feed).
  Future<Map<String, PostReactionState>> fetchReactionsForPosts(
      List<String> postIds,
      ) async {
    if (postIds.isEmpty) return {};

    try {
      final List<dynamic> response = await _client.rpc(
        'get_post_reactions',
        params: {
          'p_post_ids': postIds,
        },
      );

      final Map<String, PostReactionState> states = {};
      for (final row in response) {
        final map = row as Map<String, dynamic>;
        states[map['post_id'] as String] = PostReactionState.fromMap(map);
      }
      return states;
    } catch (e) {
      print('Error fetching reactions: $e');
      rethrow;
    }
  }
}