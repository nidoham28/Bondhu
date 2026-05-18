import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/profile/widgets/profile_tile.dart';
import 'package:bondhu/features/profile/widgets/section_wrapper.dart';
import 'package:flutter/material.dart';

/// Settings section: notifications, privacy, theme, language.
class ProfileSettingsSection extends StatelessWidget {
  final ValueChanged<String> onShowSnackBar;

  const ProfileSettingsSection({
    super.key,
    required this.onShowSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    return SectionWrapper(
      title: 'সেটিংস',
      children: [
        ProfileTile(
          icon: Icons.notifications_outlined,
          iconColor: AppColors.iconYellow,
          title: 'নোটিফিকেশন',
          subtitle: 'অ্যালার্ট ও রিমাইন্ডার',
          onTap: () => onShowSnackBar('শীঘ্রই আসছে'),
        ),
        const ProfileDivider(),
        ProfileTile(
          icon: Icons.shield_outlined,
          iconColor: AppColors.iconBlue,
          title: 'গোপনীয়তা ও নিরাপত্তা',
          subtitle: 'পাসওয়ার্ড, দুই-স্তর যাচাই',
          onTap: () => onShowSnackBar('শীঘ্রই আসছে'),
        ),
        const ProfileDivider(),
        ProfileTile(
          icon: Icons.palette_outlined,
          iconColor: AppColors.iconPink,
          title: 'থিম ও অ্যাপিয়ারেন্স',
          subtitle: Theme.of(context).brightness == Brightness.dark
              ? 'ডার্ক মোড চালু'
              : 'লাইট মোড চালু',
          onTap: () => onShowSnackBar('শীঘ্রই আসছে'),
        ),
        const ProfileDivider(),
        ProfileTile(
          icon: Icons.language_rounded,
          iconColor: AppColors.iconIndigo,
          title: 'ভাষা',
          subtitle: 'বাংলা',
          onTap: () => onShowSnackBar('শীঘ্রই আসছে'),
        ),
      ],
    );
  }
}