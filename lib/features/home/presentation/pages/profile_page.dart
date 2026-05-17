import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeader(colorScheme: colorScheme, isDark: isDark),
          ),

          // ── Action Buttons ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'প্রোফাইল সম্পাদনা',
                      icon: Icons.edit_rounded,
                      isPrimary: true,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  _IconActionButton(
                    icon: Icons.share_rounded,
                    onTap: () {},
                    tooltip: 'শেয়ার',
                  ),
                  const SizedBox(width: 10),
                  _IconActionButton(
                    icon: Icons.more_horiz_rounded,
                    onTap: () {},
                    tooltip: 'আরও',
                  ),
                ],
              ),
            ),
          ),

          // ── Section: অ্যাকাউন্ট ──────────────────────────────────
          _SectionHeader(title: 'অ্যাকাউন্ট'),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: colorScheme.primary,
                      title: 'আমার প্রোফাইল',
                      subtitle: 'নাম, ছবি, বায়ো',
                      onTap: () {},
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.bookmark_outline_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'সেভ করা পোস্ট',
                      subtitle: 'আপনার সংগ্রহ',
                      onTap: () {},
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.bar_chart_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'অ্যাক্টিভিটি',
                      subtitle: 'পোস্ট, লাইক, কমেন্ট',
                      onTap: () {},
                    ),
                  ],
                ),
              ]),
            ),
          ),

          // ── Section: সেটিংস ──────────────────────────────────────
          _SectionHeader(title: 'সেটিংস'),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'নোটিফিকেশন',
                      subtitle: 'অ্যালার্ট ও রিমাইন্ডার',
                      onTap: () {},
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'গোপনীয়তা ও নিরাপত্তা',
                      subtitle: 'পাসওয়ার্ড, দুই-স্তর যাচাই',
                      onTap: () {},
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.palette_outlined,
                      iconColor: const Color(0xFFEC4899),
                      title: 'থিম ও অ্যাপিয়ারেন্স',
                      subtitle: isDark ? 'ডার্ক মোড চালু' : 'লাইট মোড চালু',
                      onTap: () {},
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'ভাষা',
                      subtitle: 'বাংলা',
                      onTap: () {},
                    ),
                  ],
                ),
              ]),
            ),
          ),

          // ── Section: সাহায্য ─────────────────────────────────────
          _SectionHeader(title: 'সাহায্য'),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: const Color(0xFF06B6D4),
                      title: 'সাহায্য কেন্দ্র',
                      subtitle: 'প্রশ্ন ও উত্তর',
                      onTap: () {},
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF64748B),
                      title: 'অ্যাপ সম্পর্কে',
                      subtitle: 'সংস্করণ ১.০.০',
                      onTap: () {},
                    ),
                  ],
                ),
              ]),
            ),
          ),

          // ── Logout Button ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _ProfileCard(
                children: [
                  _ProfileTile(
                    icon: Icons.logout_rounded,
                    iconColor: colorScheme.error,
                    title: 'লগআউট',
                    subtitle: 'অ্যাকাউন্ট থেকে বের হন',
                    titleColor: colorScheme.error,
                    showChevron: false,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // Handle logout
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Footer ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Bondhu • সংস্করণ ১.০.০',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Profile Header
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.colorScheme, required this.isDark});
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.tertiary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              // Avatar with online indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person_rounded, size: 52, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Name
              const Text(
                'ব্যবহারকারী',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),

              // Email with icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alternate_email_rounded,
                      size: 13, color: Colors.white.withOpacity(0.75)),
                  const SizedBox(width: 4),
                  Text(
                    'user@example.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(count: '১২০', label: 'পোস্ট', icon: Icons.grid_on_rounded),
                    _StatDivider(),
                    _StatItem(count: '৪৫০', label: 'ফলোয়ার', icon: Icons.people_outline_rounded),
                    _StatDivider(),
                    _StatItem(count: '২১০', label: 'ফলোয়িং', icon: Icons.person_add_alt_1_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: Colors.white.withOpacity(0.25),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  const _StatItem({required this.count, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action Buttons
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: isPrimary ? colorScheme.primary : colorScheme.secondaryContainer,
        foregroundColor: isPrimary ? colorScheme.onPrimary : colorScheme.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Card wrapper — rounded card groups tiles
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tile
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.showChevron = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Intra-card divider
// ─────────────────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 70,
      endIndent: 0,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
    );
  }
}