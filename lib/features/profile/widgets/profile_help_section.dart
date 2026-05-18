import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/profile/widgets/profile_tile.dart';
import 'package:bondhu/features/profile/widgets/section_wrapper.dart';
import 'package:flutter/material.dart';

/// Help section: help center, about app.
class ProfileHelpSection extends StatelessWidget {
  final ValueChanged<String> onShowSnackBar;

  const ProfileHelpSection({
    super.key,
    required this.onShowSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    return SectionWrapper(
      title: 'সাহায্য',
      children: [
        ProfileTile(
          icon: Icons.help_outline_rounded,
          iconColor: AppColors.iconCyan,
          title: 'সাহায্য কেন্দ্র',
          subtitle: 'প্রশ্ন ও উত্তর',
          onTap: () => onShowSnackBar('শীঘ্রই আসছে'),
        ),
        const ProfileDivider(),
        ProfileTile(
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.iconSlate,
          title: 'অ্যাপ সম্পর্কে',
          subtitle: 'সংস্করণ ১.০.০',
          onTap: () => onShowSnackBar('শীঘ্রই আসছে'),
        ),
      ],
    );
  }
}