import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/posts/widgets/bottom_sheet_shell.dart';
import 'package:flutter/material.dart';

const _feelings = [
  ('😊', 'Happy'), ('😢', 'Sad'), ('😍', 'Loved'), ('😎', 'Cool'), ('🤔', 'Thoughtful'),
  ('🥳', 'Celebratory'), ('😡', 'Angry'), ('😴', 'Tired'), ('🤩', 'Excited'), ('😌', 'Blessed'),
  ('🙏', 'Grateful'), ('💪', 'Motivated'), ('😤', 'Determined'), ('🤗', 'Thankful'), ('🥺', 'Emotional'),
  ('🫡', 'Proud'), ('🤭', 'Surprised'), ('😏', 'Confident'),
];

class FeelingSheet extends StatelessWidget {
  const FeelingSheet({super.key, required this.current, required this.onSelect});

  final String? current;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomSheetShell(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('How are you feeling?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ext.textPrimary)),
              const Spacer(),
              if (current != null)
                TextButton(
                  onPressed: () { onSelect(null); Navigator.pop(context); },
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _feelings.map((f) {
              final label = '${f.$1} ${f.$2}';
              final selected = label == current;
              return GestureDetector(
                onTap: () { onSelect(label); Navigator.pop(context); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.iconYellow.withValues(alpha: 0.15) : ext.surfaceVariant,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: selected ? AppColors.iconYellow : ext.outline.withValues(alpha: 0.5), width: selected ? 1.5 : 0.5),
                  ),
                  child: Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? AppColors.iconYellow : ext.textPrimary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}