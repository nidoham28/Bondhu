import 'package:bondhu/features/home/presentation/providers/home_tab_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bondhu/config/constants.dart';
import 'package:bondhu/services/supabase_service.dart';
import 'package:bondhu/features/home/presentation/pages/home_feed_page.dart';
import 'package:bondhu/features/home/presentation/pages/search_page.dart';
import 'package:bondhu/features/home/presentation/pages/chats_page.dart';
import 'package:bondhu/features/home/presentation/pages/notifications_page.dart';
import 'package:bondhu/features/home/presentation/pages/profile_page.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(homeTabIndexProvider);
    final notifier = ref.read(homeTabIndexProvider.notifier);

    return Scaffold(
      appBar: _buildDynamicAppBar(context, ref, tabIndex),
      body: IndexedStack(
        index: tabIndex,
        children: const [
          HomeFeedPage(),
          SearchPage(),
          ChatsPage(),
          NotificationsPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (index) => notifier.state = index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'হোম',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'সার্চ',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'চ্যাট',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'নোটিফিকেশন',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'প্রোফাইল',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildDynamicAppBar(
      BuildContext context,
      WidgetRef ref,
      int tabIndex,
      ) {
    return AppBar(
      title: Text(_getAppBarTitle(tabIndex)),
      actions: [
        // Feed-specific filter
        if (tabIndex == 0)
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'ফিল্টার',
            onPressed: () => _showFeedFilterDialog(context),
          ),
        // Quick jump to search from other tabs
        if (tabIndex != 1)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'সার্চ',
            onPressed: () => ref.read(homeTabIndexProvider.notifier).state = 1,
          ),
        // Logout
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'সাইন আউট',
          onPressed: () => _handleLogout(context),
        ),
      ],
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return AppConstants.appName;
      case 1:
        return 'সার্চ করুন';
      case 2:
        return 'মেসেজ';
      case 3:
        return 'নোটিফিকেশন';
      case 4:
        return 'আমার প্রোফাইল';
      default:
        return AppConstants.appName;
    }
  }

  void _showFeedFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ফিড ফিল্টার'),
        content: const Text('কাস্টম ফিল্টার অপশন এখানে আসবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ করুন')),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    await SupabaseService.signOut();
    if (context.mounted) context.go('/login');
  }
}