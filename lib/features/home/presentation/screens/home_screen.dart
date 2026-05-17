import 'package:bondhu/features/profile/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bondhu/config/constants.dart';
import 'package:bondhu/features/home/providers/home_tab_provider.dart';
import 'package:bondhu/features/home/presentation/pages/home_feed_page.dart';
import 'package:bondhu/features/home/presentation/pages/chats_page.dart';
import 'package:bondhu/features/home/presentation/pages/pages_page.dart';
import 'package:bondhu/features/home/presentation/pages/community_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _navAnimController;

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(homeTabIndexProvider);
    final notifier = ref.read(homeTabIndexProvider.notifier);
    final _ = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Keep status bar icons in sync with theme
    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      )
          : SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    return Scaffold(
      // ── KEY FIX: extendBodyBehindAppBar prevents color change on scroll ──
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: _BondhuAppBar(context: context),

      body: IndexedStack(
        index: tabIndex,
        children: const [
          HomeFeedPage(),
          ChatsPage(),
          PagesPage(),
          CommunityPage(),
          ProfilePage(),
        ],
      ),

      bottomNavigationBar: _BondhuNavBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          notifier.state = index;
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Transparent + Blur AppBar — colour NEVER changes on scroll
// ─────────────────────────────────────────────────────────────
class _BondhuAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BondhuAppBar({required this.context});

  final BuildContext context;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext _) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      // ── These two lines are the core fix ──
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent, // Prevents M3 scroll tint
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0, // ← disables the elevation color shift
      elevation: 0,

      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),

      flexibleSpace: _AppBarBlurBackground(isDark: isDark),

      // Back button — hidden on top-level screens
      leading: Builder(
        builder: (ctx) => ctx.canPop()
            ? IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        )
            : const SizedBox.shrink(),
      ),

      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppConstants.appName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      centerTitle: true,

      actions: [
        // Search
        _AppBarIconBtn(
          icon: Icons.search_rounded,
          tooltip: 'Search',
          onTap: () => context.push('/search'),
        ),

        // Notifications with badge
        _NotificationButton(
          count: 3, // Replace with ref.watch(notificationCountProvider)
          onTap: () => context.push('/notifications'),
        ),

        const SizedBox(width: 4),
      ],
    );
  }
}

/// Frosted-glass / subtle gradient background for the app bar.
/// Gives depth without altering colour on scroll.
class _AppBarBlurBackground extends StatelessWidget {
  const _AppBarBlurBackground({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      decoration: BoxDecoration(
        // Gradient that fades out at the bottom so content bleeds through
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bg.withValues(alpha:  isDark ? 0.92 : 0.95),
            bg.withValues(alpha:  isDark ? 0.70 : 0.80),
            bg.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.75, 1.0],
        ),
      ),
    );
  }
}

/// Animated icon button used in the app bar.
class _AppBarIconBtn extends StatefulWidget {
  const _AppBarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_AppBarIconBtn> createState() => _AppBarIconBtnState();
}

class _AppBarIconBtnState extends State<_AppBarIconBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    _ctrl.reverse().then((_) => _ctrl.forward());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        icon: Icon(widget.icon, size: 22),
        onPressed: _onTap,
        tooltip: widget.tooltip,
        style: IconButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Notification icon button with an animated badge.
class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _AppBarIconBtn(
          icon: count > 0
              ? Icons.notifications_rounded
              : Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onTap: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Bottom Navigation Bar — refined with smooth indicator
// ─────────────────────────────────────────────────────────────
class _BondhuNavBar extends StatelessWidget {
  const _BondhuNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.95)
            : colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        animationDuration: const Duration(milliseconds: 350),
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Pages',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2_rounded),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle),
            selectedIcon: Icon(Icons.account_circle_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}