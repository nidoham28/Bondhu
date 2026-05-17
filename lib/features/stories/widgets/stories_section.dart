import 'package:flutter/material.dart';
import 'package:bondhu/features/stories/models/story_model.dart';
import 'package:bondhu/features/stories/widgets/story_avatar.dart';

class StoriesSection extends StatelessWidget {
  final List<StoryModel> stories;
  final VoidCallback onYourStoryTap;
  final ValueChanged<int> onStoryTap;

  const StoriesSection({
    super.key,
    required this.stories,
    required this.onYourStoryTap,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          if (story.isYourStory) {
            return _YourStoryCircleItem(
              story: story,
              onTap: onYourStoryTap,
            );
          }
          return _StoryCircleItem(
            story: story,
            onTap: () => onStoryTap(index),
          );
        },
      ),
    );
  }
}

class _StoryCircleItem extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const _StoryCircleItem({
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            // FIX #2: Show profileImageUrl — story circles always
            // display the user's profile pic with a ring indicator,
            // NOT the story content image.
            StoryAvatar(
              imageUrl: story.profileImageUrl,
              hasSeen: story.hasSeen,
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 68,
              child: Text(
                story.displayName,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YourStoryCircleItem extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const _YourStoryCircleItem({
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // FIX #2: Show profileImageUrl for "Your Story" too
                StoryAvatar(
                  imageUrl: story.profileImageUrl,
                  hasSeen: true,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2.5,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 14,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 68,
              child: Text(
                'Your Story',
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}