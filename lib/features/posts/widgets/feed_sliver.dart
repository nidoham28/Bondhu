import 'package:bondhu/features/posts/providers/feed_provider.dart';
import 'package:bondhu/features/posts/widgets/post_card.dart';
import 'package:bondhu/features/reactions/models/reaction_model.dart';
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
    widget.scrollController.addListener(_onScroll);
    Future.microtask(
          () => ref.read(feedProvider.notifier).fetchInitialPosts(),
    );
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final pos = widget.scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      ref.read(feedProvider.notifier).fetchMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final theme = Theme.of(context);

    // Initial Loading State
    if (feedState.status == FeedStatus.refreshing && feedState.posts.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    // Error State (No posts cached)
    if (feedState.status == FeedStatus.error && feedState.posts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load feed',
          subtitle: feedState.errorMessage ?? 'Check your connection and try again.',
          theme: theme,
          onRetry: () => ref.read(feedProvider.notifier).fetchInitialPosts(),
        ),
      );
    }

    // Empty Feed State
    if (feedState.posts.isEmpty && feedState.status == FeedStatus.success) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          icon: Icons.photo_library_outlined,
          title: 'Nothing here yet',
          subtitle: 'Follow people or share your first post!',
          theme: theme,
        ),
      );
    }

    // Main List
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          // Bottom pagination loader
          if (index == feedState.posts.length) {
            return feedState.status == FeedStatus.loadingMore
                ? const _BottomLoader()
                : const SizedBox.shrink();
          }

          final post = feedState.posts[index];
          final reactionState = feedState.reactionStates[post.id] ??
              const PostReactionState(
                userReaction: null,
                totalCount: 0,
                reactionCounts: {},
              );

          return PostCard(
            key: ValueKey(post.id),
            post: post,
            reactionState: reactionState,
            onReact: (type) => ref
                .read(feedProvider.notifier)
                .toggleReaction(post.id, type),
            onProfileTap: () {
              // TODO: Navigate to profile
            },
          );
        },
        childCount: feedState.posts.length + 1,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;
  final VoidCallback? onRetry;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomLoader extends StatelessWidget {
  const _BottomLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      ),
    );
  }
}