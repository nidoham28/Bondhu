import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PagesPage extends StatelessWidget {
  const PagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          child: InkWell(
            onTap: () => context.push('/page/$index'),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 80, width: 80, decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.pages, size: 40, color: theme.colorScheme.primary)),
                const SizedBox(height: 12),
                Text('Page ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('1.2K followers', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
      },
    );
  }
}