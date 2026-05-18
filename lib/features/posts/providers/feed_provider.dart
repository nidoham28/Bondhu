import 'package:bondhu/features/posts/models/feed_models.dart';
import 'package:bondhu/features/posts/repository/posts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FeedStatus { initial, loading, refreshing, loadingMore, success, error }

class FeedState {
  final List<Post> posts;
  final FeedStatus status;
  final String? errorMessage;
  final bool hasMore;

  const FeedState({
    this.posts = const [],
    this.status = FeedStatus.initial,
    this.errorMessage,
    this.hasMore = true,
  });

  FeedState copyWith({
    List<Post>? posts,
    FeedStatus? status,
    String? errorMessage,
    bool? hasMore,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      status: status ?? this.status,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final FeedPostsRepository _repository;

  FeedNotifier(this._repository) : super(const FeedState());

  Future<void> fetchInitialPosts() async {
    if (state.status == FeedStatus.refreshing) return;

    state = state.copyWith(status: FeedStatus.refreshing);

    try {
      await _repository.fetchInitialPosts();
      state = state.copyWith(
        posts: _repository.posts,
        hasMore: _repository.hasMore,
        status: FeedStatus.success,
      );
    } catch (e) {
      state = state.copyWith(
        status: FeedStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> fetchMorePosts() async {
    if (!_repository.hasMore || _repository.isFetching) return;

    state = state.copyWith(status: FeedStatus.loadingMore);

    try {
      await _repository.fetchMorePosts();
      state = state.copyWith(
        posts: _repository.posts,
        hasMore: _repository.hasMore,
        status: FeedStatus.success,
      );
    } catch (e) {
      state = state.copyWith(
        status: FeedStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

// Providers
final feedRepositoryProvider = Provider<FeedPostsRepository>((ref) {
  return FeedPostsRepository();
});

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return FeedNotifier(repository);
});