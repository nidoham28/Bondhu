import 'package:bondhu/features/profile/models/user_profile.dart';
import 'package:flutter/material.dart';

/// Displays display name, @username, and bio below the avatar.
class ProfileIdentityInfo extends StatelessWidget {
  final UserProfile profile;

  const ProfileIdentityInfo({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Display Name ───────────────────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                profile.displayName.isEmpty
                    ? profile.username
                    : profile.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (profile.isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, size: 20, color: Colors.blue),
            ],
          ],
        ),
        // ── Username ───────────────────────────────────────────
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.alternate_email_rounded,
              size: 13,
              color: Colors.white.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 4),
            Text(
              profile.username,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ],
        ),
        // ── Bio ────────────────────────────────────────────────
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              profile.bio!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}