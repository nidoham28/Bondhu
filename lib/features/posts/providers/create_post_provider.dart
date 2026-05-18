import 'dart:io';
import 'package:bondhu/compressor/image_compressor.dart';
import 'package:bondhu/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  DOMAIN — Audience
// ═════════════════════════════════════════════════════════════════════════════

enum PostAudience { public, private, followers, friendsOnly }

extension PostAudienceExt on PostAudience {
  String get label => switch (this) {
    PostAudience.public      => 'Public',
    PostAudience.private     => 'Private',
    PostAudience.followers   => 'Followers',
    PostAudience.friendsOnly => 'Friends Only',
  };

  String get dbValue => switch (this) {
    PostAudience.public      => 'PUBLIC',
    PostAudience.private     => 'PRIVATE',
    PostAudience.followers   => 'FOLLOWERS',
    PostAudience.friendsOnly => 'FRIENDS_ONLY',
  };

  IconData get icon => switch (this) {
    PostAudience.public      => Icons.public_rounded,
    PostAudience.private     => Icons.lock_rounded,
    PostAudience.followers   => Icons.people_outline_rounded,
    PostAudience.friendsOnly => Icons.group_rounded,
  };

  String get description => switch (this) {
    PostAudience.public      => 'Anyone on Bondhu',
    PostAudience.private     => 'Only visible to you',
    PostAudience.followers   => 'Your followers only',
    PostAudience.friendsOnly => 'Your friends only',
  };
}

// ═════════════════════════════════════════════════════════════════════════════
//  HELPERS
// ═════════════════════════════════════════════════════════════════════════════

String? resolveAvatarUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  return SupabaseService.client.storage.from('avatars').getPublicUrl(raw);
}

// ═════════════════════════════════════════════════════════════════════════════
//  STATE
// ═════════════════════════════════════════════════════════════════════════════

class CreatePostState {
  const CreatePostState({
    this.caption        = '',
    this.media          = const [],
    this.audience       = PostAudience.public,
    this.location,
    this.feeling,
    this.isSubmitting   = false,
    this.submitProgress = 0.0,
  });

  final String        caption;
  final List<XFile>   media;
  final PostAudience  audience;
  final String?       location;
  final String?       feeling;
  final bool          isSubmitting;
  final double        submitProgress;

  bool get hasContent => caption.trim().isNotEmpty || media.isNotEmpty;

  CreatePostState copyWith({
    String?       caption,
    List<XFile>?  media,
    PostAudience? audience,
    String?       location,
    bool          clearLocation = false,
    String?       feeling,
    bool          clearFeeling  = false,
    bool?         isSubmitting,
    double?       submitProgress,
  }) =>
      CreatePostState(
        caption:        caption      ?? this.caption,
        media:          media        ?? this.media,
        audience:       audience     ?? this.audience,
        location:       clearLocation ? null : location ?? this.location,
        feeling:        clearFeeling  ? null : feeling  ?? this.feeling,
        isSubmitting:   isSubmitting  ?? this.isSubmitting,
        submitProgress: submitProgress ?? this.submitProgress,
      );
}

// ═════════════════════════════════════════════════════════════════════════════
//  NOTIFIER
// ═════════════════════════════════════════════════════════════════════════════

class CreatePostNotifier extends Notifier<CreatePostState> {
  @override
  CreatePostState build() => const CreatePostState();

  void updateCaption(String v)     => state = state.copyWith(caption: v);
  void setAudience(PostAudience a) => state = state.copyWith(audience: a);

  void setLocation(String? l) => state = l == null
      ? state.copyWith(clearLocation: true)
      : state.copyWith(location: l);

  void setFeeling(String? f) => state = f == null
      ? state.copyWith(clearFeeling: true)
      : state.copyWith(feeling: f);

  Future<void> pickFromGallery() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      state = state.copyWith(media: [...state.media, ...picked]);
    }
  }

  Future<void> pickFromCamera() async {
    final photo = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo != null) {
      state = state.copyWith(media: [...state.media, photo]);
    }
  }

  void removeMedia(int index) {
    final updated = [...state.media]..removeAt(index);
    state = state.copyWith(media: updated);
  }

  Future<bool> submit() async {
    if (!state.hasContent) return false;
    state = state.copyWith(isSubmitting: true, submitProgress: 0.0);

    try {
      final uid = SupabaseService.auth.currentUser?.id;
      if (uid == null) {
        state = state.copyWith(isSubmitting: false);
        return false;
      }

      final List<String> mediaUrls = [];
      final compressor = BondhuImageCompressor.instance;

      for (int i = 0; i < state.media.length; i++) {
        final xFile = state.media[i];
        final file = File(xFile.path);

        state = state.copyWith(submitProgress: (i / state.media.length) * 0.8);

        final compressionResult = await compressor.compressForPost(file);

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storagePath = '$uid/${timestamp}_$i.webp';

        await SupabaseService.client.storage
            .from('post-images')
            .upload(storagePath, compressionResult.file);

        final publicUrl = SupabaseService.client.storage
            .from('post-images')
            .getPublicUrl(storagePath);

        mediaUrls.add(publicUrl);
      }

      state = state.copyWith(submitProgress: 0.9);

      final response = await SupabaseService.client.functions.invoke(
        'publish-post',
        body: {
          'caption':   state.caption.trim(),
          'media_urls': mediaUrls,
          'audience':  state.audience.dbValue,
          'location':  state.location,
          'feeling':   state.feeling,
        },
      );

      if (response.status != 201) {
        throw Exception('Server failed to publish post: ${response.data}');
      }

      state = state.copyWith(submitProgress: 1.0);
      return true;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return false;
    }
  }
}

final createPostProvider =
NotifierProvider<CreatePostNotifier, CreatePostState>(
    CreatePostNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────

final currentUserProvider =
FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = SupabaseService.auth.currentUser?.id;
  if (uid == null) return null;

  return SupabaseService.client
      .from('users')
      .select('uid, username, display_name, avatar_url, is_private')
      .eq('uid', uid)
      .maybeSingle();
});