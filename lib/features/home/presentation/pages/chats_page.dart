import 'package:flutter/material.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Stack(
            children: [
              const CircleAvatar(radius: 24, backgroundColor: Colors.grey),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    border: Border.all(color: Colors.white, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          title: const Text('অর্জিত রায়', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('হ্যালো! কেমন আছো? 👋', maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('১০:৩০', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              if (index == 0) const SizedBox(height: 4),
              if (index == 0) const CircleAvatar(radius: 9, backgroundColor: Colors.blue, child: Text('2', style: TextStyle(color: Colors.white, fontSize: 10))),
            ],
          ),
          onTap: () => Navigator.pushNamed(context, '/chat_detail'), // Update with go_router
        );
      },
    );
  }
}