import 'package:flutter/material.dart';

class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(child: _FeedHeader()),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) => const _PostCard(),
            childCount: 4, // Replace with real data length
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ফিড', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('আপনার বন্ধুদের সর্বশেষ আপডেট এখানে পাবেন',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard();
  @override
  Widget build(BuildContext context) {
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('রাহুল দাস', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('২ ঘণ্টা আগে', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 12),
            const Text('বন্ধুত্বের এক নতুন অধ্যায় শুরু হচ্ছে। শীঘ্রই অনেক সুন্দর ফিচার আসছে! 🌟'),
            const SizedBox(height: 12),
            Container(height: 180, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _FeedAction(icon: Icons.thumb_up_alt_outlined, label: 'লাইক'),
                _FeedAction(icon: Icons.comment_outlined, label: 'কমেন্ট'),
                _FeedAction(icon: Icons.share_outlined, label: 'শেয়ার'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeedAction({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}