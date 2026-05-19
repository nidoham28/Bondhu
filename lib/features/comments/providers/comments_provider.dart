// lib/features/comments/providers/comments_provider.dart

import 'package:bondhu/features/comments/models/comment_model.dart';
import 'package:bondhu/features/comments/repositories/comment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Repository provider ────────────────────────────────────────────────────

final commentRepositoryProvider = Provider<CommentRepository>(
      (_) => CommentRepository(),
);

// ── State Notifier ─────────────────────────────────────────────────────────

class CommentsNotifier extends StateNotifier<CommentsState> {
  final CommentRepository _repo;
  final String postId;

  static const _pageSize = 20;

  CommentsNotifier(this._repo, this.postId) : super(const CommentsState());

  // ── Fetch (initial / refresh) ──────────────────────────────────────────

  Future<void> fetchInitial() async {
    if (state.status == CommentsStatus.loading) return;
    state = state.copyWith(
      status:   CommentsStatus.loading,
      comments: [],
      hasMore:  true,
      cursor:   null,
    );

    try {
      final comments = await _repo.fetchComments(
        postId: postId,
        limit:  _pageSize,
      );
      state = state.copyWith(
        status:   CommentsStatus.success,
        comments: comments,
        hasMore:  comments.length >= _pageSize,
        cursor:   comments.isEmpty ? null : comments.last.createdAt,
      );
    } catch (e) {
      state = state.copyWith(
        status:       CommentsStatus.error,
        errorMessage: _friendlyError(e),
      );
    }
  }

  // ── Load more (pagination) ─────────────────────────────────────────────

  Future<void> loadMore() async {
    if (!state.hasMore) return;
    if (state.status == CommentsStatus.loadingMore) return;
    if (state.cursor == null) return;

    state = state.copyWith(status: CommentsStatus.loadingMore);

    try {
      final more = await _repo.fetchComments(
        postId: postId,
        limit:  _pageSize,
        cursor: state.cursor,
      );
      state = state.copyWith(
        status:   CommentsStatus.success,
        comments: [...state.comments, ...more],
        hasMore:  more.length >= _pageSize,
        cursor:   more.isEmpty ? state.cursor : more.last.createdAt,
      );
    } catch (e) {
      // Revert to success so user can retry
      state = state.copyWith(status: CommentsStatus.success);
    }
  }

  // ── Add comment ────────────────────────────────────────────────────────

  /// Returns the new [Comment] on success, or throws.
  Future<Comment> addComment(String body, {String? parentId}) async {
    // Optimistic insert is intentionally skipped — server returns the
    // comment with server-assigned id/timestamps so we can append cleanly.
    final comment = await _repo.addComment(
      postId:   postId,
      body:     body,
      parentId: parentId,
    );

    state = state.copyWith(
      comments: [...state.comments, comment],
    );

    return comment;
  }

  // ── Delete comment ─────────────────────────────────────────────────────

  Future<void> deleteComment(String commentId) async {
    // Optimistic remove
    final previous = state.comments;
    state = state.copyWith(
      comments: state.comments.where((c) => c.id != commentId).toList(),
    );

    try {
      await _repo.deleteComment(commentId);
    } catch (_) {
      // Rollback on failure
      state = state.copyWith(comments: previous);
      rethrow;
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('UNAUTHENTICATED'))   return 'Please log in to view comments.';
    if (msg.contains('POST_NOT_FOUND'))    return 'This post no longer exists.';
    return 'Something went wrong. Please try again.';
  }
}

// ── Provider (keyed by postId) ─────────────────────────────────────────────

final commentsProvider = StateNotifierProvider.family<CommentsNotifier, CommentsState, String>(
      (ref, postId) => CommentsNotifier(
    ref.read(commentRepositoryProvider),
    postId,
  ),
);