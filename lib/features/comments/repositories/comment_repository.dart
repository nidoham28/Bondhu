// lib/features/comments/repositories/comment_repository.dart

import 'package:bondhu/features/comments/models/comment_model.dart';
import 'package:bondhu/services/supabase_service.dart';

class CommentRepository {
  static final _client = SupabaseService.client;

  /// Fetch paginated top-level comments for [postId].
  Future<List<Comment>> fetchComments({
    required String postId,
    int limit = 20,
    DateTime? cursor,
  }) async {
    final response = await _client.rpc('fetch_comments', params: {
      'p_post_id': postId,
      'p_limit':   limit,
      if (cursor != null) 'p_cursor': cursor.toIso8601String(),
    });

    if (response == null) return [];
    final list = response as List<dynamic>;
    return list.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch paginated replies for a specific comment.
  Future<List<Comment>> fetchReplies({
    required String parentId,
    int limit = 20,
    DateTime? cursor,
  }) async {
    final response = await _client.rpc('fetch_replies', params: {
      'p_parent_id': parentId,
      'p_limit':     limit,
      if (cursor != null) 'p_cursor': cursor.toIso8601String(),
    });

    if (response == null) return [];
    final list = response as List<dynamic>;
    return list.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Add a new comment or reply. Returns the freshly created [Comment].
  Future<Comment> addComment({
    required String postId,
    required String body,
    String? parentId,
  }) async {
    final response = await _client.rpc('add_comment', params: {
      'p_post_id':   postId,
      'p_body':      body,
      if (parentId != null) 'p_parent_id': parentId,
    });

    return Comment.fromJson(response as Map<String, dynamic>);
  }

  /// Soft-deletes a comment.
  Future<void> deleteComment(String commentId) async {
    await _client.rpc('delete_comment', params: {'p_comment_id': commentId});
  }

  /// Toggles a reaction on a comment. Returns the updated reaction payload.
  Future<Map<String, dynamic>> toggleReaction({
    required String commentId,
    required String reactionType,
  }) async {
    final response = await _client.rpc('toggle_comment_reaction', params: {
      'p_comment_id':   commentId,
      'p_reaction_type': reactionType,
    });
    return response as Map<String, dynamic>;
  }
}