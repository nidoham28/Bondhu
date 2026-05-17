import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String uid;
  final String username;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? website;
  final String gender;
  final DateTime? dateOfBirth;
  final String language;
  final String? country;
  final String provider;
  final String role;
  final String status;
  final bool isVerified;
  final bool isPrivate;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final int postsCount;

  const UserProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.website,
    required this.gender,
    this.dateOfBirth,
    required this.language,
    this.country,
    required this.provider,
    required this.role,
    required this.status,
    required this.isVerified,
    required this.isPrivate,
    required this.isOnline,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
    required this.followersCount,
    required this.followingCount,
    required this.friendsCount,
    required this.postsCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    return UserProfile(
      uid:             j['uid'] as String,
      username:        j['username'] as String,
      displayName:     j['display_name'] as String? ?? '',
      email:           j['email'] as String,
      phoneNumber:     j['phone_number'] as String?,
      avatarUrl:       j['avatar_url'] as String?,
      coverUrl:        j['cover_url'] as String?,
      bio:             j['bio'] as String?,
      website:         j['website'] as String?,
      gender:          j['gender'] as String? ?? 'PREFER_NOT_TO_SAY',
      dateOfBirth:     j['date_of_birth'] != null
          ? DateTime.tryParse(j['date_of_birth'] as String)
          : null,
      language:        j['language'] as String? ?? 'en',
      country:         j['country'] as String?,
      provider:        j['provider'] as String? ?? 'email',
      role:            j['role'] as String? ?? 'USER',
      status:          j['status'] as String? ?? 'ACTIVE',
      isVerified:      j['is_verified'] as bool? ?? false,
      isPrivate:       j['is_private'] as bool? ?? false,
      isOnline:        j['is_online'] as bool? ?? false,
      createdAt:       DateTime.parse(j['created_at'] as String),
      updatedAt:       DateTime.parse(j['updated_at'] as String),
      lastSeenAt:      j['last_seen_at'] != null
          ? DateTime.tryParse(j['last_seen_at'] as String)
          : null,
      followersCount:  (j['followers_count'] as num?)?.toInt() ?? 0,
      followingCount:  (j['following_count'] as num?)?.toInt() ?? 0,
      friendsCount:    (j['friends_count'] as num?)?.toInt() ?? 0,
      postsCount:      (j['posts_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid, 'username': username, 'display_name': displayName,
    'email': email, 'phone_number': phoneNumber, 'avatar_url': avatarUrl,
    'cover_url': coverUrl, 'bio': bio, 'website': website,
    'gender': gender, 'date_of_birth': dateOfBirth?.toIso8601String(),
    'language': language, 'country': country, 'provider': provider,
    'role': role, 'status': status, 'is_verified': isVerified,
    'is_private': isPrivate, 'is_online': isOnline,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'last_seen_at': lastSeenAt?.toIso8601String(),
    'followers_count': followersCount, 'following_count': followingCount,
    'friends_count': friendsCount, 'posts_count': postsCount,
  };

  UserProfile copyWith({
    String? displayName, String? bio, String? website,
    String? gender, DateTime? dateOfBirth, String? language,
    String? country, String? avatarUrl, String? coverUrl,
    int? followersCount, int? followingCount, int? friendsCount,
    int? postsCount, bool? isOnline, bool? isVerified,
  }) {
    return UserProfile(
      uid: uid, username: username, email: email,
      phoneNumber: phoneNumber, provider: provider, role: role,
      status: status, isPrivate: isPrivate, createdAt: createdAt,
      updatedAt: updatedAt, lastSeenAt: lastSeenAt,
      displayName:     displayName     ?? this.displayName,
      bio:             bio             ?? this.bio,
      website:         website         ?? this.website,
      gender:          gender          ?? this.gender,
      dateOfBirth:     dateOfBirth     ?? this.dateOfBirth,
      language:        language        ?? this.language,
      country:         country         ?? this.country,
      avatarUrl:       avatarUrl       ?? this.avatarUrl,
      coverUrl:        coverUrl        ?? this.coverUrl,
      followersCount:  followersCount  ?? this.followersCount,
      followingCount:  followingCount  ?? this.followingCount,
      friendsCount:    friendsCount    ?? this.friendsCount,
      postsCount:      postsCount      ?? this.postsCount,
      isOnline:        isOnline        ?? this.isOnline,
      isVerified:      isVerified      ?? this.isVerified,
    );
  }

  /// Resolves avatar URL — handles full URLs and storage paths.
  String? resolvedAvatarUrl() {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;
    if (avatarUrl!.startsWith('http')) return avatarUrl;
    // Storage path → public URL
    return Supabase.instance.client.storage
        .from('avatars')
        .getPublicUrl(avatarUrl!);
  }

  /// Human-readable language name.
  String get languageLabel {
    const map = {
      'bn': 'বাংলা', 'en': 'English', 'hi': 'हिन्दी',
    };
    return map[language] ?? language.toUpperCase();
  }

  /// Gender display name.
  String get genderLabel {
    const map = {
      'MALE': 'পুরুষ', 'FEMALE': 'মহিলা', 'NON_BINARY': 'নন-বাইনারি',
      'OTHER': 'অন্যান্য', 'PREFER_NOT_TO_SAY': 'বলতে চাই না',
    };
    return map[gender] ?? gender;
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Formats an int count compactly (1200 → 1.2K) then converts to Bengali digits.
extension CountFormat on int {
  static const _bengali = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];

  String toBengaliDigits() {
    return toString().split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? _bengali[d] : c;
    }).join();
  }

  String toCompactBengali() {
    if (this >= 1000000) {
      final v = (this / 1000000).toStringAsFixed(1);
      return '${_convertDigits(v)}M';
    }
    if (this >= 1000) {
      final v = (this / 1000).toStringAsFixed(1);
      return '${_convertDigits(v)}K';
    }
    return toBengaliDigits();
  }

  static String _convertDigits(String s) {
    return s.split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? _bengali[d] : c;
    }).join();
  }
}