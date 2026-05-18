import 'package:bondhu/features/posts/models/feed_models.dart';
import 'package:bondhu/features/posts/repository/posts_repository.dart';
import 'package:bondhu/features/reactions/models/reaction_model.dart';
import 'package:bondhu/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

enum FeedStatus { initial, loading, refreshing, loadingMore, success, error }

@immutable
class FeedState {
  final List<Post> posts;
  final FeedStatus status;
  final String? errorMessage;
  final bool hasMore;
  final Map<String, PostReactionState> reactionStates;

  const FeedState({
    this.posts = const [],
    this.status = FeedStatus.initial,
    this.errorMessage,
    this.hasMore = true,
    this.reactionStates = const {},
  });

  // Sentinel pattern to allow explicitly setting errorMessage to null
  static const _unset = Object();

  FeedState copyWith({
    List<Post>? posts,
    FeedStatus? status,
    Object? errorMessage = _unset,
    bool? hasMore,
    Map<String, PostReactionState>? reactionStates,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      hasMore: hasMore ?? this.hasMore,
      // Guarantee deep immutability for maps
      reactionStates: reactionStates != null
          ? Map.unmodifiable(reactionStates)
          : this.reactionStates,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final FeedPostsRepository _repository;

  FeedNotifier(this._repository) : super(const FeedState());

  // ── Fetch Initial Posts & Reactions ──────────────────────────────────

  Future<void> fetchInitialPosts() async {
    // Guard: skip if already fetching
    if (state.status == FeedStatus.refreshing ||
        state.status == FeedStatus.loadingMore) {
      return;
    }

    state = state.copyWith(
      status: FeedStatus.refreshing,
      errorMessage: null, // Clear previous errors on fresh fetch
    );

    try {
      // Repository returns fresh list, no internal caching conflict
      final posts = await _repository.fetchInitialPosts();

      Map<String, PostReactionState> reactionStates = {};
      if (posts.isNotEmpty) {
        final postIds = posts.map((p) => p.id).toList();
        reactionStates =
        await SupabaseService.reactions.fetchReactionsForPosts(postIds);
      }

      state = state.copyWith(
        posts: posts,
        hasMore: _repository.hasMore,
        reactionStates: reactionStates,
        status: FeedStatus.success,
      );
    } catch (e) {
      debugPrint('Error fetching initial feed: $e');
      state = state.copyWith(
        status: FeedStatus.error,
        errorMessage: e.toString(),
        // Keep previous posts intact on error so user doesn't see a blank screen
      );
    }
  }

  // ── Fetch More Posts & Reactions (Pagination) ─────────────────────────

  Future<void> fetchMorePosts() async {
    if (!_repository.hasMore || _repository.isFetching) return;
    if (state.status == FeedStatus.loadingMore) return;

    state = state.copyWith(status: FeedStatus.loadingMore);

    try {
      // Repository returns ONLY the new paginated posts
      final newPosts = await _repository.fetchMorePosts();

      Map<String, PostReactionState> newReactionStates = {};
      if (newPosts.isNotEmpty) {
        final newPostIds = newPosts.map((p) => p.id).toList();
        newReactionStates = await SupabaseService.reactions
            .fetchReactionsForPosts(newPostIds);
      }

      // Merge new reactions into existing reactions map
      final mergedReactionStates =
      Map<String, PostReactionState>.from(state.reactionStates)
        ..addAll(newReactionStates);

      state = state.copyWith(
        posts: [...state.posts, ...newPosts], // Append new posts
        hasMore: _repository.hasMore,
        reactionStates: mergedReactionStates,
        status: FeedStatus.success,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('Error fetching more feed: $e');
      state = state.copyWith(
        status: FeedStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Optimistic Reaction Toggle ─────────────────────────────────────────

  Future<void> toggleReaction(String postId, String reactionType) async {
    final oldState = state;
    final oldRS = oldState.reactionStates[postId] ?? PostReactionState.empty();

    // ── Optimistic local update ───────────────────────────────────────
    // Leverages the built-in domain logic from PostReactionState
    final newRS = oldRS.toggleReaction(reactionType);

    state = oldState.copyWith(
      reactionStates: Map<String, PostReactionState>.from(oldState.reactionStates)
        ..[postId] = newRS,
    );

    // ── Server sync ───────────────────────────────────────────────────
    try {
      final serverRS = await SupabaseService.reactions.toggleReaction(
        postId: postId,
        reactionType: reactionType,
      );
      // Reconcile with server truth
      state = state.copyWith(
        reactionStates: Map<String, PostReactionState>.from(state.reactionStates)
          ..[postId] = serverRS,
      );
    } catch (e) {
      debugPrint('Error toggling reaction: $e');
      // Revert to pre-tap state on failure
      state = oldState;
    }
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final feedRepositoryProvider = Provider<FeedPostsRepository>((ref) {
  return FeedPostsRepository();
});

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return FeedNotifier(repository);
});