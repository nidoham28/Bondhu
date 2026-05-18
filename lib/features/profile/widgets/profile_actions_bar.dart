import 'package:bondhu/features/profile/widgets/action_button.dart';
import 'package:flutter/material.dart';

/// Action buttons row for the current user's own profile.
class OwnProfileActions extends StatelessWidget {
  final VoidCallback onEdit;
  final ValueChanged<String> onShowSnackBar;

  const OwnProfileActions({
    super.key,
    required this.onEdit,
    required this.onShowSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: ActionButton(
              label: 'প্রোফাইল সম্পাদনা',
              icon: Icons.edit_rounded,
              isPrimary: true,
              onTap: onEdit,
            ),
          ),
          const SizedBox(width: 10),
          IconActionButton(
            icon: Icons.share_rounded,
            onTap: () => onShowSnackBar('শেয়ার ফিচার শীঘ্রই আসছে'),
            tooltip: 'শেয়ার',
          ),
          const SizedBox(width: 10),
          IconActionButton(
            icon: Icons.more_horiz_rounded,
            onTap: () => onShowSnackBar('আরও অপশন শীঘ্রই আসছে'),
            tooltip: 'আরও',
          ),
        ],
      ),
    );
  }
}

/// Action buttons row for viewing another user's profile.
class OtherUserActions extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final ValueChanged<String> onShowSnackBar;

  const OtherUserActions({
    super.key,
    required this.isFollowing,
    required this.onToggleFollow,
    required this.onShowSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: ActionButton(
              label: isFollowing ? 'ফলোয়িং' : 'ফলো করুন',
              icon: isFollowing
                  ? Icons.check_rounded
                  : Icons.person_add_rounded,
              isPrimary: !isFollowing,
              onTap: onToggleFollow,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ActionButton(
              label: 'মেসেজ',
              icon: Icons.chat_bubble_outline_rounded,
              isPrimary: false,
              onTap: () => onShowSnackBar('মেসেজিং শীঘ্রই আসছে'),
            ),
          ),
          const SizedBox(width: 10),
          IconActionButton(
            icon: Icons.more_horiz_rounded,
            onTap: () => onShowSnackBar('আরও অপশন শীঘ্রই আসছে'),
            tooltip: 'আরও',
          ),
        ],
      ),
    );
  }
}