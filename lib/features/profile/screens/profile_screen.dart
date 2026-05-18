import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/profile/models/user_profile.dart';
import 'package:bondhu/features/profile/repositories/profile_repository.dart';
import 'package:bondhu/features/profile/pages/edit_profile_sheet.dart';
import 'package:bondhu/features/profile/widgets/profile_header.dart';
import 'package:bondhu/features/profile/widgets/profile_actions_bar.dart';
import 'package:bondhu/features/profile/widgets/profile_account_section.dart';
import 'package:bondhu/features/profile/widgets/profile_settings_section.dart';
import 'package:bondhu/features/profile/widgets/profile_help_section.dart';
import 'package:bondhu/features/profile/widgets/profile_logout_section.dart';
import 'package:bondhu/features/profile/widgets/loading_error_views.dart';
import 'package:bondhu/services/supabase_service.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Profile Screen — Main Orchestrator
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;
  late final bool _isCurrentUser;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.uid == SupabaseService.auth.currentUser?.id;
    _loadProfile();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = _isCurrentUser
          ? await ProfileRepository.fetchMyProfile()
          : await ProfileRepository.fetchProfile(widget.uid);

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

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লগআউট'),
        content: const Text('আপনি কি নিশ্চিত যে আপনি লগআউট করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'হ্যাঁ',
              style: TextStyle(color: AppColors.iconRed),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ProfileRepository.signOut();
    } catch (_) {
      if (mounted) _showSnackBar('লগআউট করতে সমস্যা হয়েছে');
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

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    _showSnackBar(_isFollowing ? 'ফলো করা হয়েছে' : 'আনফলো করা হয়েছে');
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) return const ProfileLoadingView();
    if (_error != null) {
      return ProfileErrorView(error: _error!, onRetry: _loadProfile);
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: ProfileHeader(profile: _profile!)),
          SliverToBoxAdapter(
            child: _isCurrentUser
                ? _OwnProfileBody(
              profile: _profile!,
              onEdit: _openEditSheet,
              onSignOut: _handleSignOut,
              onShowSnackBar: _showSnackBar,
            )
                : _OtherProfileBody(
              isFollowing: _isFollowing,
              onToggleFollow: _toggleFollow,
              onShowSnackBar: _showSnackBar,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Screen-Specific Layout Composers (private to this screen)
// ─────────────────────────────────────────────────────────────────────────────

class _OwnProfileBody extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onSignOut;
  final ValueChanged<String> onShowSnackBar;

  const _OwnProfileBody({
    required this.profile,
    required this.onEdit,
    required this.onSignOut,
    required this.onShowSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OwnProfileActions(onEdit: onEdit, onShowSnackBar: onShowSnackBar),
        ProfileAccountSection(profile: profile, onEdit: onEdit),
        ProfileSettingsSection(onShowSnackBar: onShowSnackBar),
        ProfileHelpSection(onShowSnackBar: onShowSnackBar),
        ProfileLogoutSection(onSignOut: onSignOut),
      ],
    );
  }
}

class _OtherProfileBody extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final ValueChanged<String> onShowSnackBar;

  const _OtherProfileBody({
    required this.isFollowing,
    required this.onToggleFollow,
    required this.onShowSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    return OtherUserActions(
      isFollowing: isFollowing,
      onToggleFollow: onToggleFollow,
      onShowSnackBar: onShowSnackBar,
    );
  }
}