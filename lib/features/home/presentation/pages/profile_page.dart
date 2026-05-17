import 'package:bondhu/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _ProfileHeader()),

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
                  _IconActionButton(icon: Icons.share_rounded, onTap: () {}, tooltip: 'শেয়ার'),
                  const SizedBox(width: 10),
                  _IconActionButton(icon: Icons.more_horiz_rounded, onTap: () {}, tooltip: 'আরও'),
                ],
              ),
            ),
          ),

          // ── অ্যাকাউন্ট ───────────────────────────────────────────
          const _SectionHeader(title: 'অ্যাকাউন্ট'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _ProfileCard(children: [
                _ProfileTile(icon: Icons.person_outline_rounded, iconColor: AppColors.iconPurple,
                    title: 'আমার প্রোফাইল', subtitle: 'নাম, ছবি, বায়ো', onTap: () {}),
                _Divider(),
                _ProfileTile(icon: Icons.bookmark_outline_rounded, iconColor: AppColors.iconIndigo,
                    title: 'সেভ করা পোস্ট', subtitle: 'আপনার সংগ্রহ', onTap: () {}),
                _Divider(),
                _ProfileTile(icon: Icons.bar_chart_rounded, iconColor: AppColors.iconGreen,
                    title: 'অ্যাক্টিভিটি', subtitle: 'পোস্ট, লাইক, কমেন্ট', onTap: () {}),
              ]),
            ),
          ),

          // ── সেটিংস ───────────────────────────────────────────────
          const _SectionHeader(title: 'সেটিংস'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _ProfileCard(children: [
                _ProfileTile(icon: Icons.notifications_outlined, iconColor: AppColors.iconYellow,
                    title: 'নোটিফিকেশন', subtitle: 'অ্যালার্ট ও রিমাইন্ডার', onTap: () {}),
                _Divider(),
                _ProfileTile(icon: Icons.shield_outlined, iconColor: AppColors.iconBlue,
                    title: 'গোপনীয়তা ও নিরাপত্তা', subtitle: 'পাসওয়ার্ড, দুই-স্তর যাচাই', onTap: () {}),
                _Divider(),
                _ProfileTile(icon: Icons.palette_outlined, iconColor: AppColors.iconPink,
                    title: 'থিম ও অ্যাপিয়ারেন্স',
                    subtitle: Theme.of(context).brightness == Brightness.dark ? 'ডার্ক মোড চালু' : 'লাইট মোড চালু',
                    onTap: () {}),
                _Divider(),
                _ProfileTile(icon: Icons.language_rounded, iconColor: AppColors.iconIndigo,
                    title: 'ভাষা', subtitle: 'বাংলা', onTap: () {}),
              ]),
            ),
          ),

          // ── সাহায্য ──────────────────────────────────────────────
          const _SectionHeader(title: 'সাহায্য'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _ProfileCard(children: [
                _ProfileTile(icon: Icons.help_outline_rounded, iconColor: AppColors.iconCyan,
                    title: 'সাহায্য কেন্দ্র', subtitle: 'প্রশ্ন ও উত্তর', onTap: () {}),
                _Divider(),
                _ProfileTile(icon: Icons.info_outline_rounded, iconColor: AppColors.iconSlate,
                    title: 'অ্যাপ সম্পর্কে', subtitle: 'সংস্করণ ১.০.০', onTap: () {}),
              ]),
            ),
          ),

          // ── Logout ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _ProfileCard(children: [
                _ProfileTile(icon: Icons.logout_rounded, iconColor: AppColors.iconRed,
                    title: 'লগআউট', subtitle: 'অ্যাকাউন্ট থেকে বের হন',
                    titleColor: AppColors.iconRed, showChevron: false,
                    onTap: () => HapticFeedback.mediumImpact()),
              ]),
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
                  color: context.appColors.textSecondary.withValues(alpha: 0.5),
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
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final ext = context.appColors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ext.dashHeaderStart, ext.dashHeaderEnd],
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
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: const CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person_rounded, size: 52, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: ext.onlineIndicator,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Text('ব্যবহারকারী',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              const SizedBox(height: 4),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alternate_email_rounded, size: 13, color: Colors.white.withValues(alpha: 0.75)),
                  const SizedBox(width: 4),
                  Text('user@example.com', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ),

              const SizedBox(height: 24),

              // Stat cards — colors come from AppColorExtension
              Row(
                children: [
                  _StatCard(bg: ext.dashStatCard1, iconColor: AppColors.dashStatIcon1,
                      icon: Icons.grid_on_rounded, count: '১২০', label: 'পোস্ট'),
                  const SizedBox(width: 10),
                  _StatCard(bg: ext.dashStatCard2, iconColor: AppColors.dashStatIcon2,
                      icon: Icons.people_outline_rounded, count: '৪৫০', label: 'ফলোয়ার'),
                  const SizedBox(width: 10),
                  _StatCard(bg: ext.dashStatCard3, iconColor: AppColors.dashStatIcon3,
                      icon: Icons.person_add_alt_1_rounded, count: '২১০', label: 'ফলোয়িং'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.bg, required this.iconColor, required this.icon, required this.count, required this.label});
  final Color bg;
  final Color iconColor;
  final IconData icon;
  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 6),
            Text(count, style: TextStyle(color: iconColor, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: iconColor.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared widgets
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.isPrimary, required this.onTap});
  final String label; final IconData icon; final bool isPrimary; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton.icon(
      onPressed: () { HapticFeedback.lightImpact(); onTap(); },
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: isPrimary ? cs.primary : cs.secondaryContainer,
        foregroundColor: isPrimary ? cs.onPrimary : cs.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({required this.icon, required this.onTap, required this.tooltip});
  final IconData icon; final VoidCallback onTap; final String tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Text(title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.appColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ext = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: ext.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.outline.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle, required this.onTap,
    this.titleColor, this.showChevron = true,
  });
  final IconData icon; final Color iconColor;
  final String title; final String subtitle; final VoidCallback onTap;
  final Color? titleColor; final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final ext = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600, color: titleColor ?? ext.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ext.textSecondary, fontSize: 11)),
                ]),
              ),
              if (showChevron)
                Icon(Icons.chevron_right_rounded, size: 20, color: ext.textSecondary.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 0.5, indent: 70, color: context.appColors.outline.withValues(alpha: 0.4));
  }
}