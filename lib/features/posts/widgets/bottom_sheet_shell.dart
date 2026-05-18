import 'package:bondhu/config/theme.dart';
import 'package:flutter/material.dart';

class BottomSheetShell extends StatelessWidget {
  const BottomSheetShell({super.key, required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: ext.outline.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          child,
        ],
      ),
    );
  }
}