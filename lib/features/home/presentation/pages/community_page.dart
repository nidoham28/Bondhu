import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(Icons.group, color: Theme.of(context).colorScheme.primary)),
            title: Text('Tech Enthusiasts ${index + 1}'),
            subtitle: Text('${index * 120 + 50} members • 12 online now'),
            trailing: ElevatedButton(onPressed: () {}, child: const Text('Join')),
            onTap: () => context.push('/community/$index'),
          ),
        );
      },
    );
  }
}