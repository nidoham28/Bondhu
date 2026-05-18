import 'package:bondhu/services/supabase_service.dart'; // Your provided service

class PostAuthor {
  final String uid;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  final bool isPrivate;

  PostAuthor({
    required this.uid,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.isVerified,
    required this.isPrivate,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      uid: json['published_by'] ?? '',
      username: json['author_username'] ?? '',
      displayName: json['author_display_name'] ?? '',
      // Fixed: Using the proper resolver below
      avatarUrl: _resolveAvatarUrl(json['author_avatar_url'] as String?),
      isVerified: json['author_is_verified'] ?? false,
      isPrivate: json['author_is_private'] ?? false,
    );
  }

  /// Fixed Resolver: No manual string interpolation. Uses SupabaseService safely.
  static String? _resolveAvatarUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    // If it's already a full URL (e.g., from Google/OAuth), return as-is
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    // Otherwise, it's a storage path. Use the official Supabase storage method.
    // This avoids the `supabaseUrl` error entirely.
    return SupabaseService.client.storage
        .from('avatars')
        .getPublicUrl(raw);
  }
}

class Post {
  final String id;
  final String publishedBy;
  final String type;
  final String? caption;
  final List<String> mediaUrls;
  final String? feeling;
  final String? location;
  final String audience;
  final int reactionsCount;
  final int commentCount;
  final int shareCount;
  final int viewsCount;
  final bool sponsored;
  final DateTime createdAt;
  final PostAuthor author;

  Post({
    required this.id,
    required this.publishedBy,
    required this.type,
    this.caption,
    required this.mediaUrls,
    this.feeling,
    this.location,
    required this.audience,
    required this.reactionsCount,
    required this.commentCount,
    required this.shareCount,
    required this.viewsCount,
    required this.sponsored,
    required this.createdAt,
    required this.author,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      publishedBy: json['published_by'],
      type: json['type'] ?? 'UNKNOWN',
      caption: json['caption'],
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      feeling: json['feeling'],
      location: json['location'],
      audience: json['audience'] ?? 'PUBLIC',
      reactionsCount: json['reactions_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      sponsored: json['sponsored'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      author: PostAuthor.fromJson(json), // Author fields are flat in the JSON
    );
  }
}