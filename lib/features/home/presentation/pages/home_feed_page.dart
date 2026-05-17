import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bondhu/features/stories/managers/story_manager.dart';
import 'package:bondhu/features/stories/models/story_model.dart';
import 'package:bondhu/features/stories/screens/story_publish_screen.dart';
import 'package:bondhu/features/stories/screens/story_viewer_screen.dart';
import 'package:bondhu/features/stories/widgets/stories_section.dart';

class HomeFeedPage extends ConsumerStatefulWidget {
  const HomeFeedPage({super.key});

  @override
  ConsumerState<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends ConsumerState<HomeFeedPage> {
  @override
  void initState() {
    super.initState();
    // Subscribe to realtime updates once the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyManagerProvider.notifier).subscribeToRealtime();
    });
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onYourStoryTap() async {
    final storyState = ref.read(storyManagerProvider).valueOrNull;

    // If user already has active stories → open viewer (Instagram style)
    if (storyState != null && storyState.hasMyActiveStories) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StoryViewerScreen(
            stories: storyState.myActiveStories,
            initialIndex: 0,
            onStorySeen: (_) {}, // Own stories don't need view tracking
          ),
        ),
      );
      return;
    }

    // No active stories → open publish screen
    final result = await Navigator.of(context).push<StoryModel>(
      MaterialPageRoute(builder: (_) => const StoryPublishScreen()),
    );

    // If a story was successfully published, refresh the manager
    if (result != null) {
      await ref.read(storyManagerProvider.notifier).refresh();
    }
  }

  void _onStoryTap(int index) {
    final storyState = ref.read(storyManagerProvider).valueOrNull;
    if (storyState == null) return;

    // Index 0 is always the placeholder — guard against out-of-bounds
    if (index <= 0 || index >= storyState.stories.length) return;

    final tappedStory = storyState.stories[index];
    final viewableStories = storyState.viewableStories;
    if (viewableStories.isEmpty) return;

    // Find where this story sits in the flat viewable list
    final viewerIndex = viewableStories.indexWhere((s) => s.id == tappedStory.id);
    if (viewerIndex == -1) return; // No image URL or not viewable — skip

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          stories: viewableStories,
          initialIndex: viewerIndex,
          onStorySeen: (storyId) {
            ref.read(storyManagerProvider.notifier).markAsSeen(storyId);
          },
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storyAsync = ref.watch(storyManagerProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(storyManagerProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even if content is small
        slivers: [
          SliverToBoxAdapter(
            child: storyAsync.when(
              loading: () => const SizedBox(
                height: 112,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SizedBox(
                height: 112,
                child: Center(
                  child: Text(
                    'Could not load stories',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
              data: (storyState) => StoriesSection(
                stories: storyState.stories,
                onYourStoryTap: _onYourStoryTap,
                onStoryTap: _onStoryTap,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(
              height: 32,
              thickness: 0.5,
              // Changed withValues to withOpacity for broader Flutter compatibility
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}