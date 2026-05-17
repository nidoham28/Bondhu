import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bondhu/features/profile/models/user_profile.dart';

class ProfileRepository {
  ProfileRepository._();
  static final _client = Supabase.instance.client;

  // ── Fetch current user's profile ──────────────────────────────────────────
  static Future<UserProfile> fetchMyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final row = await _client
        .from('users')
        .select()
        .eq('uid', uid)
        .single();

    return UserProfile.fromJson(row);
  }

  // ── Fetch any user's public profile ───────────────────────────────────────
  static Future<UserProfile> fetchProfile(String uid) async {
    final row = await _client
        .from('public_profiles')
        .select()
        .eq('uid', uid)
        .single();

    return UserProfile.fromJson(row);
  }

  // ── Upload avatar to Supabase Storage ────────────────────────────────────
  /// Uploads [file] to the `avatars` bucket under `{uid}/avatar.<ext>` and
  /// returns the public URL. The upload always upserts (overwrites) the
  /// previous avatar so the path stays stable.
  static Future<String> uploadAvatar(File file) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final bytes = await file.readAsBytes();
    final ext   = file.path.split('.').last.toLowerCase(); // usually 'webp'
    final path  = '$uid/avatar.$ext';

    await _client.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        upsert:      true,
        contentType: 'image/webp',
      ),
    );

    // Append a cache-buster so Flutter's NetworkImage picks up the new file.
    final baseUrl = _client.storage.from('avatars').getPublicUrl(path);
    final ts      = DateTime.now().millisecondsSinceEpoch;
    return '$baseUrl?t=$ts';
  }

  // ── Upload cover photo to Supabase Storage ────────────────────────────────
  /// Uploads [file] to the `covers` bucket under `{uid}/cover.<ext>` and
  /// returns the public URL.
  static Future<String> uploadCover(File file) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final bytes = await file.readAsBytes();
    final ext   = file.path.split('.').last.toLowerCase();
    final path  = '$uid/cover.$ext';

    await _client.storage.from('covers').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        upsert:      true,
        contentType: 'image/webp',
      ),
    );

    final baseUrl = _client.storage.from('covers').getPublicUrl(path);
    final ts      = DateTime.now().millisecondsSinceEpoch;
    return '$baseUrl?t=$ts';
  }

  // ── Update profile via RPC ────────────────────────────────────────────────
  static Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? website,
    String? gender,
    DateTime? dateOfBirth,
    String? language,
    String? country,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    await _client.rpc('update_user_profile', params: {
      'p_uid':           uid,
      'p_display_name':  displayName,
      'p_bio':           bio,
      'p_website':       website,
      'p_gender':        gender,
      'p_date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'p_language':      language,
      'p_country':       country,
      'p_avatar_url':    avatarUrl,
      'p_cover_url':     coverUrl,
    });
  }

  // ── Online status ─────────────────────────────────────────────────────────
  static Future<void> setOnline(bool isOnline) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.rpc('set_user_online', params: {
      'p_uid':    uid,
      'p_online': isOnline,
    });
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() => _client.auth.signOut();
}