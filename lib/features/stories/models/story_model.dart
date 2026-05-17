class StoryModel {
  final String id;
  final String userId;

  // Fetched relationally from public.users
  final String username;
  final String displayName;
  final String? profileImageUrl;

  final String? storyImageUrl;
  final String? textOverlay;
  final String? musicUrl;
  final String? location;
  final String fontFamily;
  final String textColor;
  final int totalViews;

  final bool hasSeen; // Server-authoritative
  final bool isYourStory; // Server-authoritative
  final DateTime timestamp;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    this.profileImageUrl,
    this.storyImageUrl,
    this.textOverlay,
    this.musicUrl,
    this.location,
    this.fontFamily = 'Roboto',
    this.textColor = '#FFFFFF',
    this.totalViews = 0,
    this.hasSeen = false,
    this.isYourStory = false,
    required this.timestamp,
  });

  /// Maps Supabase relational data to Client Model
  factory StoryModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final userId = json['user_id'] as String;

    // Safely extract the nested 'users' object
    // Supabase sometimes returns joins as a List `[{}]` instead of a Map `{}`
    final rawUsers = json['users'];
    final Map<String, dynamic> userData;

    if (rawUsers is Map<String, dynamic>) {
      userData = rawUsers;
    } else if (rawUsers is List && rawUsers.isNotEmpty) {
      userData = (rawUsers.first as Map<String, dynamic>?) ?? {};
    } else {
      userData = {};
    }

    // FIX #3: Supabase can return numeric columns as num/double
    int parseTotalViews(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    return StoryModel(
      id: json['id'] as String,
      userId: userId,
      username: userData['username'] as String? ?? 'unknown',
      displayName: userData['display_name'] as String? ?? 'Unknown',
      profileImageUrl: userData['avatar_url'] as String?,
      storyImageUrl: json['image_url'] as String?,
      textOverlay: json['text_overlay'] as String?,
      musicUrl: json['music_url'] as String?,
      location: json['location'] as String?,
      fontFamily: json['font_family'] as String? ?? 'Roboto',
      textColor: json['text_color'] as String? ?? '#FFFFFF',
      totalViews: parseTotalViews(json['total_views']),
      isYourStory: json['is_your_story'] as bool? ?? (userId == currentUserId),
      hasSeen: json['has_seen'] as bool? ?? false,
      timestamp: DateTime.parse(json['created_at'] as String),
    );
  }

  StoryModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? displayName,
    String? profileImageUrl,
    String? storyImageUrl,
    String? textOverlay,
    String? musicUrl,
    String? location,
    String? fontFamily,
    String? textColor,
    int? totalViews,
    bool? hasSeen,
    bool? isYourStory,
    DateTime? timestamp,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      storyImageUrl: storyImageUrl ?? this.storyImageUrl,
      textOverlay: textOverlay ?? this.textOverlay,
      musicUrl: musicUrl ?? this.musicUrl,
      location: location ?? this.location,
      fontFamily: fontFamily ?? this.fontFamily,
      textColor: textColor ?? this.textColor,
      totalViews: totalViews ?? this.totalViews,
      hasSeen: hasSeen ?? this.hasSeen,
      isYourStory: isYourStory ?? this.isYourStory,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }
}