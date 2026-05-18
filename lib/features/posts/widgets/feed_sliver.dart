import 'package:bondhu/features/posts/providers/feed_provider.dart';
import 'package:bondhu/features/posts/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeedSliver extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const FeedSliver({super.key, required this.scrollController});

  @override
  ConsumerState<FeedSliver> createState() => _FeedSliverState();
}

class _FeedSliverState extends ConsumerState<FeedSliver> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener; _onScroll;
    // Initial fetch
    Future.microtask(() => ref.read(feedProvider.notifier).fetchInitialPosts());
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    // Trigger fetch more when user reaches 80% of the list
    if (widget.scrollController.position.pixels >= widget.scrollController.position.maxScrollExtent * 0.8) {
      ref.read(feedProvider.notifier).fetchMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final theme = Theme.of(context);

    // ── Handle Initial Loading State ──────────────────────────
    if (feedState.status == FeedStatus.refreshing && feedState.posts.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // ── Handle Error State ────────────────────────────────────
    if (feedState.status == FeedStatus.error && feedState.posts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('Failed to load feed.\n${feedState.errorMessage ?? ''}', textAlign: TextAlign.center),
        ),
      );
    }

    // ── Handle Empty State ────────────────────────────────────
    if (feedState.posts.isEmpty && feedState.status == FeedStatus.success) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('No posts yet. Follow people or create your first post!', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }

    // ── Handle Data State ─────────────────────────────────────
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          // Show loading indicator at the bottom while fetching more
          if (index == feedState.posts.length) {
            if (feedState.status == FeedStatus.loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox.shrink();
          }

          final post = feedState.posts[index];
          return PostCard(
            post: post,
            onProfileTap: () {
              // TODO: Navigate to profile
            },
          );
        },
        childCount: feedState.posts.length + (feedState.hasMore ? 1 : 0),
      ),
    );
  }
}