import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/profile/widgets/profile_tile.dart';
import 'package:bondhu/features/profile/widgets/section_wrapper.dart';
import 'package:flutter/material.dart';

/// Logout section: sign-out tile styled in red.
class ProfileLogoutSection extends StatelessWidget {
  final VoidCallback onSignOut;

  const ProfileLogoutSection({
    super.key,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SectionCard(
        children: [
          ProfileTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.iconRed,
            title: 'লগআউট',
            subtitle: 'অ্যাকাউন্ট থেকে বের হন',
            titleColor: AppColors.iconRed,
            showChevron: false,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}