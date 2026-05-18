import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/profile/models/user_profile.dart';
import 'package:flutter/material.dart';

/// Row of three stat cards: posts, followers, following.
class ProfileStatsRow extends StatelessWidget {
  final UserProfile profile;

  const ProfileStatsRow({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final ext = context.appColors;
    return Row(
      children: [
        StatCard(
          bg: ext.dashStatCard1,
          iconColor: AppColors.dashStatIcon1,
          icon: Icons.grid_on_rounded,
          count: profile.postsCount.toCompactBengali(),
          label: 'পোস্ট',
        ),
        const SizedBox(width: 10),
        StatCard(
          bg: ext.dashStatCard2,
          iconColor: AppColors.dashStatIcon2,
          icon: Icons.people_outline_rounded,
          count: profile.followersCount.toCompactBengali(),
          label: 'ফলোয়ার',
        ),
        const SizedBox(width: 10),
        StatCard(
          bg: ext.dashStatCard3,
          iconColor: AppColors.dashStatIcon3,
          icon: Icons.person_add_alt_1_rounded,
          count: profile.followingCount.toCompactBengali(),
          label: 'ফলোয়িং',
        ),
      ],
    );
  }
}

/// Individual stat card with icon, count, and label.
class StatCard extends StatelessWidget {
  final Color bg;
  final Color iconColor;
  final IconData icon;
  final String count;
  final String label;

  const StatCard({
    super.key,
    required this.bg,
    required this.iconColor,
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                color: iconColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: iconColor.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}