import 'package:flutter/material.dart';

class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        // Instagram-like Stories Row
        SliverToBoxAdapter(
          child: _StoriesSection(),
        ),
        // Divider below stories
        SliverToBoxAdapter(
          child: Divider(
            height: 32,
            thickness: 0.5,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        // Empty space for now (posts removed)
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Stories Section
// ─────────────────────────────────────────────────────────────
class _StoriesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: 50, // Max 50 stories
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _StoryItem(
              name: 'Your Story',
              isYourStory: true,
            );
          }
          return _StoryItem(
            name: _generateName(index),
            hasUnviewedStory: index % 3 != 0, // Demo: some viewed, some not
          );
        },
      ),
    );
  }

  String _generateName(int index) {
    const names = [
      'Liam', 'Sophia', 'Noah', 'Olivia', 'Ethan', 'Riley', 'Mason', 'Ava',
      'Lucas', 'Emma', 'Aiden', 'Mia', 'Jackson', 'Isabella', 'Logan', 'Aria',
    ];
    return names[index % names.length];
  }
}

class _StoryItem extends StatelessWidget {
  final String name;
  final bool isYourStory;
  final bool hasUnviewedStory;

  const _StoryItem({
    required this.name,
    this.isYourStory = false,
    this.hasUnviewedStory = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isYourStory || !hasUnviewedStory
                  ? LinearGradient(
                colors: [
                  theme.colorScheme.outlineVariant,
                  theme.colorScheme.outlineVariant,
                ],
              )
                  : const LinearGradient(
                colors: [
                  Color(0xFFF09433),
                  Color(0xFFE6683C),
                  Color(0xFFDC2743),
                  Color(0xFFCC2366),
                  Color(0xFFBC1888),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: isYourStory
                    ? Icon(
                  Icons.add,
                  color: theme.colorScheme.primary,
                  size: 28,
                )
                    : Text(
                  name[0],
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 68,
            child: Text(
              isYourStory ? 'Your Story' : name,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isYourStory
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}