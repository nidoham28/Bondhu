import 'package:bondhu/features/posts/providers/feed_provider.dart';
import 'package:bondhu/features/posts/widgets/create_post_card.dart';
import 'package:bondhu/features/posts/widgets/feed_sliver.dart';
import 'package:bondhu/features/profile/screens/profile_screen.dart';
import 'package:bondhu/features/stories/managers/story_manager.dart';
import 'package:bondhu/features/stories/models/story_model.dart';
import 'package:bondhu/features/stories/screens/story_publish_screen.dart';
import 'package:bondhu/features/stories/screens/story_viewer_screen.dart';
import 'package:bondhu/features/stories/widgets/stories_section.dart';
import 'package:bondhu/features/posts/screens/create_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeFeedPage extends ConsumerStatefulWidget {
  const HomeFeedPage({super.key});

  @override
  ConsumerState<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends ConsumerState<HomeFeedPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyManagerProvider.notifier).subscribeToRealtime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Story handlers ────────────────────────────────────────────────────

  Future<void> _onYourStoryTap() async {
    final result = await Navigator.of(context).push<StoryModel>(
      MaterialPageRoute(builder: (_) => const StoryPublishScreen()),
    );
    if (result != null) {
      await ref.read(storyManagerProvider.notifier).refresh();
    }
  }

  void _onStoryTap(int index) {
    final storyState = ref.read(storyManagerProvider).valueOrNull;
    if (storyState == null) return;
    if (index <= 0 || index >= storyState.stories.length) return;

    final tappedStory = storyState.stories[index];
    final viewableStories = storyState.viewableStories;
    if (viewableStories.isEmpty) return;

    final viewerIndex = viewableStories.indexWhere((s) => s.id == tappedStory.id);
    if (viewerIndex == -1) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          stories: viewableStories,
          initialIndex: viewerIndex,
          onStorySeen: (storyId) => ref.read(storyManagerProvider.notifier).markAsSeen(storyId),
        ),
      ),
    );
  }

  // ── Post card handlers ────────────────────────────────────────────────

  void _onProfileAvatarTap() {
    //Navigator.of(context).push(
    // MaterialPageRoute(builder: (_) => const ProfileScreen()),
    // );
  }

  Future<void> _onCreatePostTap() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storyAsync = ref.watch(storyManagerProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(storyManagerProvider.notifier).refresh(),
          ref.read(feedProvider.notifier).fetchInitialPosts(),
        ] as Iterable<Future<dynamic>>);
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: storyAsync.when(
              loading: () => const SizedBox(height: 112, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SizedBox(
                height: 112,
                child: Center(child: Text('Could not load stories', style: TextStyle(color: theme.colorScheme.error))),
              ),
              data: (storyState) => StoriesSection(
                stories: storyState.stories,
                onYourStoryTap: _onYourStoryTap,
                onStoryTap: _onStoryTap,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: CreatePostCard(
              onProfileTap: _onProfileAvatarTap,
              onCreatePostTap: _onCreatePostTap,
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(height: 32, thickness: 0.5, color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          FeedSliver(scrollController: _scrollController),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}