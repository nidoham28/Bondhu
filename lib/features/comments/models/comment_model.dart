// lib/features/comments/models/comment_model.dart

import 'package:bondhu/features/posts/models/feed_models.dart'; // reuses PostAuthor

class Comment {
  final String id;
  final String postId;
  final String? parentId;
  final String body;
  final PostAuthor author;
  final int likesCount;
  final int repliesCount;
  final DateTime createdAt;

  // ── Reaction & Threading Fields ────────────────
  final Map<String, int> reactionCounts;
  final String? userReaction;
  final List<Comment> replies;
  final bool isRepliesLoading;
  final bool hasMoreReplies;

  const Comment({
    required this.id,
    required this.postId,
    this.parentId,
    required this.body,
    required this.author,
    required this.likesCount,
    required this.repliesCount,
    required this.createdAt,
    this.reactionCounts = const {},
    this.userReaction,
    this.replies = const [],
    this.isRepliesLoading = false,
    this.hasMoreReplies = true,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final reactionMap = <String, int>{};
    if (json['reaction_counts'] != null && json['reaction_counts'] is Map) {
      (json['reaction_counts'] as Map).forEach((key, value) {
        reactionMap[key.toString()] = (value as num).toInt();
      });
    }

    return Comment(
      id:             json['id'] as String,
      postId:         json['post_id'] as String,
      parentId:       json['parent_id'] as String?,
      body:           json['body'] as String,
      author:         PostAuthor.fromJson(json['author'] as Map<String, dynamic>),
      likesCount:     (json['likes_count'] as num?)?.toInt() ?? 0,
      repliesCount:   (json['replies_count'] as num?)?.toInt() ?? 0,
      createdAt:      DateTime.parse(json['created_at'] as String),
      reactionCounts: reactionMap,
      userReaction:   json['user_reaction'] as String?,
    );
  }

  Comment copyWith({
    String? body,
    int? likesCount,
    int? repliesCount,
    Map<String, int>? reactionCounts,
    String? userReaction,
    List<Comment>? replies,
    bool? isRepliesLoading,
    bool? hasMoreReplies,
  }) {
    return Comment(
      id:               id,
      postId:           postId,
      parentId:         parentId,
      body:             body ?? this.body,
      author:           author,
      likesCount:       likesCount ?? this.likesCount,
      repliesCount:     repliesCount ?? this.repliesCount,
      createdAt:        createdAt,
      reactionCounts:   reactionCounts ?? this.reactionCounts,
      userReaction:     userReaction ?? this.userReaction,
      replies:          replies ?? this.replies,
      isRepliesLoading: isRepliesLoading ?? this.isRepliesLoading,
      hasMoreReplies:   hasMoreReplies ?? this.hasMoreReplies,
    );
  }
}

enum CommentsStatus { initial, loading, success, loadingMore, error }

class CommentsState {
  final List<Comment> comments;
  final CommentsStatus status;
  final String? errorMessage;
  final bool hasMore;
  final DateTime? cursor; // for top-level pagination

  const CommentsState({
    this.comments = const [],
    this.status = CommentsStatus.initial,
    this.errorMessage,
    this.hasMore = true,
    this.cursor,
  });

  CommentsState copyWith({
    List<Comment>? comments,
    CommentsStatus? status,
    String? errorMessage,
    bool? hasMore,
    DateTime? cursor,
  }) {
    return CommentsState(
      comments:     comments     ?? this.comments,
      status:       status       ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore:      hasMore      ?? this.hasMore,
      cursor:       cursor       ?? this.cursor,
    );
  }
}