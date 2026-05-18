import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/posts/providers/create_post_provider.dart';
import 'package:flutter/material.dart';

class UserRow extends StatelessWidget {
  const UserRow({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    required this.username,
    required this.audience,
    required this.isDark,
    required this.isPrivate,
    required this.onAudienceTap,
  });

  final String? avatarUrl;
  final String displayName;
  final String? username;
  final PostAudience audience;
  final bool isDark;
  final bool isPrivate;
  final VoidCallback onAudienceTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final ringBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [cs.primary, cs.tertiary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, color: ringBg),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: cs.primaryContainer,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null ? Icon(Icons.person, size: 22, color: cs.onPrimaryContainer) : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.textPrimary))),
                  if (isPrivate) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.lock_outline_rounded, size: 14, color: ext.textSecondary),
                  ],
                ],
              ),
              if (username != null) ...[
                const SizedBox(height: 1),
                Text('@$username', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: ext.textSecondary)),
              ],
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onAudienceTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: ext.surfaceVariant,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: ext.outline.withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(audience.icon, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(audience.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}