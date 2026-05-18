import 'package:bondhu/config/theme.dart';
import 'package:bondhu/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Provider
// ─────────────────────────────────────────────────────────────────────────────

final currentUserPhotoProvider = FutureProvider<String?>((ref) async {
  final uid = SupabaseService.currentUser?.id;
  if (uid == null) return null;

  final data = await SupabaseService.client
      .from('users')
      .select('avatar_url')
      .eq('uid', uid)
      .maybeSingle();

  return data?['avatar_url'] as String?;
});

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────

class CreatePostCard extends ConsumerWidget {
  const CreatePostCard({
    super.key,
    required this.onProfileTap,
    required this.onCreatePostTap,
  });

  final VoidCallback onProfileTap;
  final VoidCallback onCreatePostTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs       = Theme.of(context).colorScheme;
    final ext      = Theme.of(context).extension<AppColorExtension>()!;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final photoAsync = ref.watch(currentUserPhotoProvider);

    final rootBg  = isDark ? AppColors.surfaceDark  : AppColors.surfaceLight;
    final cardBg  = isDark ? AppColors.cardDark       : AppColors.cardLight;
    final outline = ext.outline.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: rootBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline, width: 0.5),
      ),
      child: Row(
        children: [
          // ── Avatar — gradient ring + circular Material ripple ──────────────
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onProfileTap,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rootBg,
                    ),
                    child: photoAsync.when(
                      data: (url) => CircleAvatar(
                        radius: 20,
                        backgroundColor: cs.primaryContainer,
                        backgroundImage: url != null ? NetworkImage(url) : null,
                        child: url == null
                            ? Icon(Icons.person, size: 22, color: cs.onPrimaryContainer)
                            : null,
                      ),
                      loading: () => CircleAvatar(
                        radius: 20,
                        backgroundColor: ext.surfaceVariant,
                      ),
                      error: (_, _) => CircleAvatar(
                        radius: 20,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.person, size: 22, color: cs.onPrimaryContainer),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── "What's on your mind?" — card surface pill ─────────────────────
          Expanded(
            child: GestureDetector(
              onTap: onCreatePostTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: outline, width: 0.5),
                ),
                child: Text(
                  "What's on your mind?",
                  style: TextStyle(
                    fontSize: 16,
                    color: ext.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Vertical divider ───────────────────────────────────────────────
          Container(
            width: 0.5,
            height: 32,
            color: outline,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),

          const SizedBox(width: 2),

          // ── Photo shortcut — circular Material ripple ──────────────────────
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onCreatePostTap,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_outlined, color: AppColors.iconGreen, size: 22),
                    const SizedBox(height: 3),
                    Text(
                      'Photo',
                      style: TextStyle(
                        fontSize: 11,
                        color: ext.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}