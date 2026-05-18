import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/posts/providers/create_post_provider.dart';
import 'package:bondhu/features/posts/widgets/bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudienceSheet extends ConsumerWidget {
  const AudienceSheet({super.key, required this.current, required this.onSelect});

  final PostAudience current;
  final void Function(PostAudience) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomSheetShell(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Post audience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ext.textPrimary)),
          const SizedBox(height: 4),
          Text('Who can see your post?', style: TextStyle(fontSize: 13, color: ext.textSecondary)),
          const SizedBox(height: 16),
          ...PostAudience.values.map((a) => AudienceOption(
            audience: a,
            isSelected: a == current,
            onTap: () {
              onSelect(a);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class AudienceOption extends StatelessWidget {
  const AudienceOption({super.key, required this.audience, required this.isSelected, required this.onTap});

  final PostAudience audience;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : ext.surfaceVariant, shape: BoxShape.circle),
                child: Icon(audience.icon, color: isSelected ? AppColors.primary : ext.textSecondary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(audience.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ext.textPrimary)),
                    const SizedBox(height: 1),
                    Text(audience.description, style: TextStyle(fontSize: 12, color: ext.textSecondary)),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSelected
                    ? const Icon(Icons.check_circle_rounded, key: ValueKey('checked'), color: AppColors.primary, size: 22)
                    : const SizedBox.shrink(key: ValueKey('unchecked')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}