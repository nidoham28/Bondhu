import 'package:flutter/material.dart';

class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text('Your Feed', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) => _FeedCard(),
            childCount: 4,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }
}

class _FeedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('User Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('2h ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ])),
                IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Modern, clean, and production-ready UI. Easily connect to your backend.'),
            const SizedBox(height: 12),
            Container(height: 180, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 12),
            const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _FeedAction(icon: Icons.thumb_up_off_alt_outlined, label: 'Like'),
              _FeedAction(icon: Icons.chat_bubble_outline, label: 'Comment'),
              _FeedAction(icon: Icons.share_outlined, label: 'Share'),
            ]),
          ],
        ),
      ),
    );
  }
}

class _FeedAction extends StatelessWidget {
  final IconData icon; final String label;
  const _FeedAction({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {}, borderRadius: BorderRadius.circular(8),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}