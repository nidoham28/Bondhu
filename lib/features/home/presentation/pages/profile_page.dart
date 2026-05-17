import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primary, primary.withValues(alpha: 0.7)]),
            ),
            child: const Column(
              children: [
                CircleAvatar(radius: 48, backgroundColor: Colors.white, child: Icon(Icons.person, size: 48, color: Colors.grey)),
                SizedBox(height: 12),
                Text('ব্যবহারকারী', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('user@example.com', style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(count: '১২০', label: 'পোস্ট'),
                    _StatItem(count: '৪৫০', label: 'ফলোয়ার'),
                    _StatItem(count: '২১০', label: 'ফলোয়িং'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProfileTile(icon: Icons.edit, title: 'প্রোফাইল সম্পাদনা', onTap: () {}),
          _ProfileTile(icon: Icons.settings, title: 'সেটিংস', onTap: () {}),
          _ProfileTile(icon: Icons.shield, title: 'গোপনীয়তা ও নিরাপত্তা', onTap: () {}),
          _ProfileTile(icon: Icons.help, title: 'সাহায্য ও সমর্থন', onTap: () {}),
          _ProfileTile(icon: Icons.info, title: 'অ্যাপ সম্পর্কে', onTap: () {}),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  const _StatItem({required this.count, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(count, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileTile({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }
}