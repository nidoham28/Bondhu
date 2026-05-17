import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/profile/models/user_profile.dart';
import 'package:bondhu/features/profile/repositories/profile_repository.dart';
import 'package:bondhu/features/profile/pages/edit_profile_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await ProfileRepository.fetchMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লগআউট'),
        content: const Text('আপনি কি নিশ্চিত যে আপনি লগআউট করতে চান?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('না')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ', style: TextStyle(color: AppColors.iconRed)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ProfileRepository.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('লগআউট করতে সমস্যা হয়েছে')),
        );
      }
    }
  }

  Future<void> _openEditSheet() async {
    if (_profile == null) return;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(profile: _profile!),
    );
    if (updated == true) _loadProfile();
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _isLoading
          ? const _LoadingShimmer()
          : _error != null
          ? _ErrorView(error: _error!, onRetry: _loadProfile)
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = _profile!;
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ─── FIX 1: Wrapped in SliverToBoxAdapter ──────────────────
          SliverToBoxAdapter(child: _ProfileHeader(profile: p)),

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
                      onTap: _openEditSheet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _IconActionButton(
                    icon: Icons.share_rounded,
                    onTap: () => _showSnackbar('শেয়ার ফিচার শীঘ্রই আসছে'),
                    tooltip: 'শেয়ার',
                  ),
                  const SizedBox(width: 10),
                  _IconActionButton(
                    icon: Icons.more_horiz_rounded,
                    onTap: () => _showSnackbar('আরও অপশন শীঘ্রই আসছে'),
                    tooltip: 'আরও',
                  ),
                ],
              ),
            ),
          ),

          // ── অ্যাকাউন্ট ─────────────────────────────────────────────
          const _SectionHeader(title: 'অ্যাকাউন্ট'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _ProfileCard(children: [
                _ProfileTile(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.iconPurple,
                  title: 'আমার প্রোফাইল',
                  subtitle: '${p.displayName} • @${p.username}',
                  onTap: _openEditSheet,
                ),
                _Divider(),
                _ProfileTile(
                  icon: Icons.bookmark_outline_rounded,
                  iconColor: AppColors.iconIndigo,
                  title: 'সেভ করা পোস্ট',
                  subtitle: 'আপনার সংগ্রহ',
                  onTap: () => _showSnackbar('শীঘ্রই আসছে'),
                ),
                _Divider(),
                _ProfileTile(
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppColors.iconGreen,
                  title: 'অ্যাক্টিভিটি',
                  subtitle:
                  'পোস্ট ${p.postsCount.toBengaliDigits()}, ফলোয়ার ${p.followersCount.toBengaliDigits()}',
                  onTap: () => _showSnackbar('শীঘ্রই আসছে'),
                ),
              ]),
            ),
          ),

          // ── সেটিংস ─────────────────────────────────────────────────
          const _SectionHeader(title: 'সেটিংস'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _ProfileCard(children: [
                _ProfileTile(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.iconYellow,
                  title: 'নোটিফিকেশন',
                  subtitle: 'অ্যালার্ট ও রিমাইন্ডার',
                  onTap: () => _showSnackbar('শীঘ্রই আসছে'),
                ),
                _Divider(),
                _ProfileTile(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.iconBlue,
                  title: 'গোপনীয়তা ও নিরাপত্তা',
                  subtitle: 'পাসওয়ার্ড, দুই-স্তর যাচাই',
                  onTap: () => _showSnackbar('শীঘ্রই আসছে'),
                ),
                _Divider(),
                _ProfileTile(
                  icon: Icons.palette_outlined,
                  iconColor: AppColors.iconPink,
                  title: 'থিম ও অ্যাপিয়ারেন্স',
                  subtitle: Theme.of(context).brightness == Brightness.dark
                      ? 'ডার্ক মোড চালু'
                      : 'লাইট মোড চালু',
                  onTap: () => _showSnackbar('শীঘ্রই আসছে'),
                ),
                _Divider(),
                _ProfileTile(
                  icon: Icons.language_rounded,
                  iconColor: AppColors.iconIndigo,
                  title: 'ভাষা',
                  subtitle: p.languageLabel,
                  onTap: () => _showSnackbar('শীঘ্রই আসছে'),
                ),
              ]),
            ),
          ),

          // ── সাহায্য ────────────────────────────────────────────────
          const _SectionHeader(title: 'সাহায্য'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _ProfileCard(children: [
                _ProfileTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.iconCyan,
                  title: 'সাহায্য কেন্দ্র',
                  subtitle: 'প্রশ্ন ও উত্তর',
                  onTap: () => _showSnackbar('শীঘ্রই আসছে'),
                ),
                _Divider(),
                _ProfileTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.iconSlate,
                  title: 'অ্যাপ সম্পর্কে',
                  subtitle: 'সংস্করণ ১.০.০',
                  onTap: () => _showSnackbar('শীঘ্রই আসছে'),
                ),
              ]),
            ),
          ),

          // ── Logout ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _ProfileCard(children: [
                _ProfileTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.iconRed,
                  title: 'লগআউট',
                  subtitle: 'অ্যাকাউন্ট থেকে বের হন',
                  titleColor: AppColors.iconRed,
                  showChevron: false,
                  onTap: _handleSignOut,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Loading shimmer
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    final ext = context.appColors;
    return Center(
      child: CircularProgressIndicator(
          color: ext.textSecondary.withValues(alpha: 0.4)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Error view
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ext = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: ext.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('প্রোফাইল লোড করা যায়নি',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ext.textSecondary)),
            const SizedBox(height: 20),
            FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('আবার চেষ্টা করুন')),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Profile Header
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final UserProfile profile;

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
              // ── Avatar ────────────────────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: _AvatarCircle(profile: profile),
                  ),
                  // Verified badge OR online dot
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: profile.isVerified
                        ? Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded,
                          size: 14, color: Colors.white),
                    )
                        : Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: profile.isOnline
                            ? ext.onlineIndicator
                            : Colors.grey,
                        shape: BoxShape.circle,
                        border:
                        Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Name ──────────────────────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      profile.displayName.isEmpty
                          ? profile.username
                          : profile.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        size: 20, color: Colors.blue),
                  ],
                ],
              ),

              const SizedBox(height: 4),

              // ── Username ──────────────────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alternate_email_rounded,
                      size: 13, color: Colors.white.withValues(alpha: 0.75)),
                  const SizedBox(width: 4),
                  Text(profile.username,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13)),
                ],
              ),

              // ── Bio ───────────────────────────────────────────────────
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    profile.bio!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12.5),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Stat cards ────────────────────────────────────────────
              Row(
                children: [
                  _StatCard(
                    bg: ext.dashStatCard1,
                    iconColor: AppColors.dashStatIcon1,
                    icon: Icons.grid_on_rounded,
                    count: profile.postsCount.toCompactBengali(),
                    label: 'পোস্ট',
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    bg: ext.dashStatCard2,
                    iconColor: AppColors.dashStatIcon2,
                    icon: Icons.people_outline_rounded,
                    count: profile.followersCount.toCompactBengali(),
                    label: 'ফলোয়ার',
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    bg: ext.dashStatCard3,
                    iconColor: AppColors.dashStatIcon3,
                    icon: Icons.person_add_alt_1_rounded,
                    count: profile.followingCount.toCompactBengali(),
                    label: 'ফলোয়িং',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FIX 2: Safely resolve URL without throwing during build ──────────────
class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.profile});
  final UserProfile profile;

  /// Safely resolves avatar URL — handles full URLs and storage paths.
  String? _resolveUrl() {
    final raw = profile.avatarUrl;
    if (raw == null || raw.isEmpty) return null;

    // Already a full URL
    if (raw.startsWith('http')) return raw;

    // Storage path → try to build public URL, but don't crash
    try {
      return Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolveUrl();

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 52,
        backgroundColor: Colors.white24,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
      );
    }

    return const CircleAvatar(
      radius: 52,
      backgroundColor: Colors.white24,
      child: Icon(Icons.person_rounded, size: 52, color: Colors.white),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.bg,
    required this.iconColor,
    required this.icon,
    required this.count,
    required this.label,
  });
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
        decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 6),
            Text(count,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  color: iconColor.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                )),
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
    final cs = Theme.of(context).colorScheme;
    return FilledButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
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
  const _IconActionButton(
      {required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
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
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
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
    final ext = context.appColors;
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: titleColor ?? ext.textPrimary)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                              color: ext.textSecondary, fontSize: 11)),
                    ]),
              ),
              if (showChevron)
                Icon(Icons.chevron_right_rounded,
                    size: 20,
                    color: ext.textSecondary.withValues(alpha: 0.5)),
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
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 70,
      color: context.appColors.outline.withValues(alpha: 0.4),
    );
  }
}