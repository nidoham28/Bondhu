import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/profile/models/user_profile.dart';
import 'package:bondhu/features/profile/widgets/profile_avatar.dart';
import 'package:bondhu/features/profile/widgets/profile_identity_info.dart';
import 'package:bondhu/features/profile/widgets/profile_stats_row.dart';
import 'package:flutter/material.dart';

/// Full-width gradient header containing avatar, identity, and stats.
class ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const ProfileHeader({super.key, required this.profile});

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
              ProfileAvatarWithBadge(profile: profile),
              const SizedBox(height: 14),
              ProfileIdentityInfo(profile: profile),
              const SizedBox(height: 24),
              ProfileStatsRow(profile: profile),
            ],
          ),
        ),
      ),
    );
  }
}