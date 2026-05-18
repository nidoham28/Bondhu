import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/profile/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Circular avatar that loads from network or shows a placeholder.
class ProfileAvatar extends StatelessWidget {
  final UserProfile profile;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.profile,
    this.radius = 52,
  });

  String? _resolveUrl() {
    final raw = profile.avatarUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    try {
      return Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolveUrl();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, _) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      child: Icon(Icons.person_rounded, size: radius, color: Colors.white),
    );
  }
}

/// Avatar with verification badge or online indicator overlay.
class ProfileAvatarWithBadge extends StatelessWidget {
  final UserProfile profile;

  const ProfileAvatarWithBadge({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final ext = context.appColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Avatar with border & shadow ────────────────────────
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ProfileAvatar(profile: profile),
        ),
        // ── Badge ──────────────────────────────────────────────
        Positioned(
          bottom: 2,
          right: 2,
          child: profile.isVerified
              ? _VerifiedBadge()
              : _OnlineIndicator(isOnline: profile.isOnline, color: ext.onlineIndicator),
        ),
      ],
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
    );
  }
}

class _OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final Color color;

  const _OnlineIndicator({required this.isOnline, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isOnline ? color : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
    );
  }
}