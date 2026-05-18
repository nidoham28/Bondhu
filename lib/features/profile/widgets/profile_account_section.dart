import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/profile/models/user_profile.dart';
import 'package:bondhu/features/profile/widgets/profile_tile.dart';
import 'package:bondhu/features/profile/widgets/section_wrapper.dart';
import 'package:flutter/material.dart';

/// Account section: profile link, saved posts, activity summary.
class ProfileAccountSection extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;

  const ProfileAccountSection({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SectionWrapper(
      title: 'অ্যাকাউন্ট',
      children: [
        ProfileTile(
          icon: Icons.person_outline_rounded,
          iconColor: AppColors.iconPurple,
          title: 'আমার প্রোফাইল',
          subtitle: '${profile.displayName} • @${profile.username}',
          onTap: onEdit,
        ),
        const ProfileDivider(),
        ProfileTile(
          icon: Icons.bookmark_outline_rounded,
          iconColor: AppColors.iconIndigo,
          title: 'সেভ করা পোস্ট',
          subtitle: 'আপনার সংগ্রহ',
          onTap: () {},
        ),
        const ProfileDivider(),
        ProfileTile(
          icon: Icons.bar_chart_rounded,
          iconColor: AppColors.iconGreen,
          title: 'অ্যাক্টিভিটি',
          subtitle:
          'পোস্ট ${profile.postsCount.toBengaliDigits()}, ফলোয়ার ${profile.followersCount.toBengaliDigits()}',
          onTap: () {},
        ),
      ],
    );
  }
}