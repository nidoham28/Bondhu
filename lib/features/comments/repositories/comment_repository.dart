// lib/features/comments/repositories/comment_repository.dart

import 'package:bondhu/features/comments/models/comment_model.dart';
import 'package:bondhu/services/supabase_service.dart';

class CommentRepository {
  static final _client = SupabaseService.client;

  /// Fetch paginated top-level comments for [postId].
  /// Pass [cursor] (createdAt of last item) for infinite scroll.
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
    return list
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Add a new comment. Throws on validation / auth error.
  /// Returns the freshly created [Comment] with server-populated fields.
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

  /// Soft-deletes a comment. Throws if not the author or already deleted.
  Future<void> deleteComment(String commentId) async {
    await _client.rpc('delete_comment', params: {'p_comment_id': commentId});
  }
}