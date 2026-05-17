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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyManagerProvider.notifier).subscribeToRealtime();
    });
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  /// Index 0 is ALWAYS the "Add Story" upload button — never a viewer.
  Future<void> _onYourStoryTap() async {
    final result = await Navigator.of(context).push<StoryModel>(
      MaterialPageRoute(builder: (_) => const StoryPublishScreen()),
    );

    if (result != null) {
      await ref.read(storyManagerProvider.notifier).refresh();
    }
  }

  /// Tapping any story at index 1+ opens the viewer.
  void _onStoryTap(int index) {
    final storyState = ref.read(storyManagerProvider).valueOrNull;
    if (storyState == null) return;

    // Index 0 is the placeholder — only _onYourStoryTap handles it
    if (index <= 0 || index >= storyState.stories.length) return;

    final tappedStory = storyState.stories[index];
    final viewableStories = storyState.viewableStories;
    if (viewableStories.isEmpty) return;

    // Find this story's position in the flat viewable list
    final viewerIndex =
    viewableStories.indexWhere((s) => s.id == tappedStory.id);
    if (viewerIndex == -1) return;

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
        physics: const AlwaysScrollableScrollPhysics(),
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
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}