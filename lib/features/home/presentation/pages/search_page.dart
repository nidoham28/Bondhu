import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ব্যক্তি, গ্রুপ বা পোস্ট খুঁজুন...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: _controller.clear)
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: (v) {}, // Add Riverpod + Supabase query here
          ),
          const SizedBox(height: 24),
          Text('রিসেন্ট সার্চ', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['ফিড', 'চ্যাট', 'প্রোফাইল সেটিংস', 'হেল্প']
                .map((t) => Chip(label: Text(t), onDeleted: () {}, deleteIcon: const Icon(Icons.close, size: 16)))
                .toList(),
          ),
          const Spacer(),
          Center(child: Text('সার্চ করলে এখানে ফলাফল দেখাবে', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey))),
        ],
      ),
    );
  }
}