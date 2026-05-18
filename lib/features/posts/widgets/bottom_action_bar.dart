import 'package:bondhu/config/theme.dart';
import 'package:flutter/material.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.surfaceBg,
    required this.onPhoto,
    required this.onCamera,
    required this.onFeeling,
    required this.onLocation,
  });

  final Color surfaceBg;
  final VoidCallback onPhoto;
  final VoidCallback onCamera;
  final VoidCallback onFeeling;
  final VoidCallback onLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surfaceBg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          ActionBtn(icon: Icons.photo_library_outlined, label: 'Photo', color: AppColors.iconGreen, onTap: onPhoto),
          ActionBtn(icon: Icons.camera_alt_outlined, label: 'Camera', color: AppColors.iconBlue, onTap: onCamera),
          ActionBtn(icon: Icons.emoji_emotions_outlined, label: 'Feeling', color: AppColors.iconYellow, onTap: onFeeling),
          ActionBtn(icon: Icons.place_outlined, label: 'Location', color: AppColors.iconRed, onTap: onLocation),
          ActionBtn(icon: Icons.person_add_alt_1_outlined, label: 'Tag', color: AppColors.iconPurple, onTap: () {}),
        ],
      ),
    );
  }
}

class ActionBtn extends StatelessWidget {
  const ActionBtn({super.key, required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 23),
                const SizedBox(height: 3),
                Text(label, style: TextStyle(fontSize: 10.5, color: ext.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}