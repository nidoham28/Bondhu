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
      final comments = await _repo.fetchComments(postId: postId, limit: _pageSize);
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
    if (!state.hasMore || state.status == CommentsStatus.loadingMore || state.cursor == null) return;

    state = state.copyWith(status: CommentsStatus.loadingMore);

    try {
      final more = await _repo.fetchComments(postId: postId, limit: _pageSize, cursor: state.cursor);
      state = state.copyWith(
        status:   CommentsStatus.success,
        comments: [...state.comments, ...more],
        hasMore:  more.length >= _pageSize,
        cursor:   more.isEmpty ? state.cursor : more.last.createdAt,
      );
    } catch (e) {
      state = state.copyWith(status: CommentsStatus.success);
    }
  }

  // ── Add top-level comment ──────────────────────────────────────────────

  Future<Comment> addComment(String body) async {
    final comment = await _repo.addComment(postId: postId, body: body);
    state = state.copyWith(comments: [...state.comments, comment]);
    return comment;
  }

  // ── Add reply to a comment ─────────────────────────────────────────────

  Future<Comment> addReply(String parentId, String body) async {
    final reply = await _repo.addComment(postId: postId, body: body, parentId: parentId);

    final updatedComments = _updateCommentInList(state.comments, parentId, (parent) {
      return parent.copyWith(
        replies: [...parent.replies, reply],
        repliesCount: parent.repliesCount + 1,
      );
    });

    state = state.copyWith(comments: updatedComments);
    return reply;
  }

  // ── Delete comment (handles deep deletion locally) ─────────────────────

  Future<void> deleteComment(String commentId) async {
    final previous = state.comments;

    // Deep filter
    final updatedComments = _removeCommentFromList(previous, commentId);
    state = state.copyWith(comments: updatedComments);

    try {
      await _repo.deleteComment(commentId);
    } catch (_) {
      state = state.copyWith(comments: previous); // Rollback
      rethrow;
    }
  }

  // ── Fetch Replies (Thread) ─────────────────────────────────────────────

  Future<void> fetchReplies(String parentCommentId) async {
    final updatedComments = _updateCommentInList(state.comments, parentCommentId, (c) => c.copyWith(isRepliesLoading: true));
    state = state.copyWith(comments: updatedComments);

    try {
      final replies = await _repo.fetchReplies(parentId: parentCommentId);
      final finalComments = _updateCommentInList(state.comments, parentCommentId, (c) => c.copyWith(
        replies: replies,
        isRepliesLoading: false,
        hasMoreReplies: replies.length >= _pageSize,
      ));
      state = state.copyWith(comments: finalComments);
    } catch (_) {
      final finalComments = _updateCommentInList(state.comments, parentCommentId, (c) => c.copyWith(isRepliesLoading: false));
      state = state.copyWith(comments: finalComments);
    }
  }

  // ── Toggle Reaction ────────────────────────────────────────────────────

  Future<void> toggleReaction(String commentId, String reactionType) async {
    final response = await _repo.toggleReaction(commentId: commentId, reactionType: reactionType);

    final newReaction = response['user_reaction'] as String?;
    final newCounts = <String, int>{};
    if (response['reaction_counts'] != null) {
      (response['reaction_counts'] as Map).forEach((key, value) {
        newCounts[key.toString()] = (value as num).toInt();
      });
    }

    final updatedComments = _updateCommentInList(state.comments, commentId, (c) => c.copyWith(
      userReaction: newReaction,
      reactionCounts: newCounts,
      likesCount: (response['total_count'] as num?)?.toInt() ?? c.likesCount,
    ));

    state = state.copyWith(comments: updatedComments);
  }

  // ── Deep List Helpers ──────────────────────────────────────────────────

  List<Comment> _updateCommentInList(List<Comment> list, String id, Comment Function(Comment) updater) {
    return list.map((c) {
      if (c.id == id) return updater(c);
      if (c.replies.isNotEmpty) {
        return c.copyWith(replies: _updateCommentInList(c.replies, id, updater));
      }
      return c;
    }).toList();
  }

  List<Comment> _removeCommentFromList(List<Comment> list, String id) {
    return list.where((c) => c.id != id).map((c) {
      if (c.replies.isNotEmpty) {
        return c.copyWith(replies: _removeCommentFromList(c.replies, id));
      }
      return c;
    }).toList();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('UNAUTHENTICATED')) return 'Please log in to view comments.';
    if (msg.contains('POST_NOT_FOUND')) return 'This post no longer exists.';
    return 'Something went wrong. Please try again.';
  }
}

// ── Provider (keyed by postId) ─────────────────────────────────────────────

final commentsProvider = StateNotifierProvider.family<CommentsNotifier, CommentsState, String>(
      (ref, postId) => CommentsNotifier(ref.read(commentRepositoryProvider), postId),
);