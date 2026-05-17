import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const _NotificationItem(icon: Icons.favorite, color: Colors.red, title: 'রাহুল দাস', subtitle: 'আপনার পোস্টে লাইক দিয়েছেন', time: '৫ মিনিট আগে', isRead: false),
        const _NotificationItem(icon: Icons.comment, color: Colors.blue, title: 'সুমিতা রায়', subtitle: 'আপনার পোস্টে কমেন্ট করেছেন: "দারুণ!"', time: '১ ঘণ্টা আগে', isRead: true),
        const _NotificationItem(icon: Icons.group_add, color: Colors.green, title: 'বন্ধুত্ব ক্লাব', subtitle: 'আপনাকে গ্রুপে অ্যাড করেছে', time: '২ দিন আগে', isRead: true),
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final bool isRead;
  const _NotificationItem({required this.icon, required this.color, required this.title, required this.subtitle, required this.time, required this.isRead});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
      title: Text.rich(TextSpan(children: [
        TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: subtitle),
      ])),
      subtitle: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
      onTap: () {},
    );
  }
}