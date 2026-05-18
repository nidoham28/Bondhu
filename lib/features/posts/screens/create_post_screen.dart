import 'dart:io';

import 'package:bondhu/compressor/image_compressor.dart';
import 'package:bondhu/config/theme.dart';
import 'package:bondhu/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String get dbValue => switch (this) {
    PostAudience.public      => 'PUBLIC',
    PostAudience.private     => 'PRIVATE',
    PostAudience.followers   => 'FOLLOWERS',
    PostAudience.friendsOnly => 'FRIENDS_ONLY',
  };
}

// ═════════════════════════════════════════════════════════════════════════════
//  HELPERS
// ═════════════════════════════════════════════════════════════════════════════

/// Resolves an avatar value from Supabase `users.avatar_url`.
/// - Full URL (`https://…`) → returned as-is.
/// - Storage path like `avatars/abc.png` → builds a public URL.
/// - `null` / empty → returns `null`.
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
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) {
        state = state.copyWith(isSubmitting: false);
        return false;
      }

      final List<String> mediaUrls = [];
      final compressor = BondhuImageCompressor.instance;

      // ── 1. Compress & Upload sequentially to preserve order ──────────
      for (int i = 0; i < state.media.length; i++) {
        final xFile = state.media[i];
        final file = File(xFile.path);

        // Update progress (reserve 80% of progress bar for compress/upload)
        state = state.copyWith(submitProgress: (i / state.media.length) * 0.8);

        // Compress using the post preset
        final compressionResult = await compressor.compressForPost(file);

        // Generate unique storage path
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storagePath = '$uid/${timestamp}_$i.webp';

        // Upload to Supabase Storage
        await SupabaseService.client.storage
            .from('post-images')
            .upload(storagePath, compressionResult.file);

        // Get Public URL and add to list
        final publicUrl = SupabaseService.client.storage
            .from('post-images')
            .getPublicUrl(storagePath);

        mediaUrls.add(publicUrl);
      }

      state = state.copyWith(submitProgress: 0.9);

      // ── 2. Call Edge Function to publish post (Server-side insert) ───
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

final _currentUserProvider =
FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = SupabaseService.currentUser?.id;
  if (uid == null) return null;

  return SupabaseService.client
      .from('public_profiles')
      .select('uid, username, display_name, avatar_url, is_private')
      .eq('uid', uid)
      .maybeSingle();
});

// ═════════════════════════════════════════════════════════════════════════════
//  FEELINGS LIST
// ═════════════════════════════════════════════════════════════════════════════

const _feelings = [
  ('😊', 'Happy'),
  ('😢', 'Sad'),
  ('😍', 'Loved'),
  ('😎', 'Cool'),
  ('🤔', 'Thoughtful'),
  ('🥳', 'Celebratory'),
  ('😡', 'Angry'),
  ('😴', 'Tired'),
  ('🤩', 'Excited'),
  ('😌', 'Blessed'),
  ('🙏', 'Grateful'),
  ('💪', 'Motivated'),
  ('😤', 'Determined'),
  ('🤗', 'Thankful'),
  ('🥺', 'Emotional'),
  ('🫡', 'Proud'),
  ('🤭', 'Surprised'),
  ('😏', 'Confident'),
];

// ═════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _captionCtrl;
  late final FocusNode _focusNode;
  late final AnimationController _shareAnim;
  late final Animation<double> _shareScale;

  static const int _maxChars = 2200;

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController();
    _focusNode = FocusNode();
    _shareAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _shareScale = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _shareAnim, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _focusNode.dispose();
    _shareAnim.dispose();
    ref.invalidate(createPostProvider);
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _onShare() async {
    _shareAnim.forward().then((_) => _shareAnim.reverse());
    final ok = await ref.read(createPostProvider.notifier).submit();
    if (ok && mounted) Navigator.of(context).pop();
  }

  void _confirmDiscard() {
    if (!ref.read(createPostProvider).hasContent) {
      Navigator.of(context).pop();
      return;
    }
    _showSheet(_DiscardSheet(
      onDiscard: () {
        Navigator.of(context)
          ..pop() // sheet
          ..pop(); // screen
      },
    ));
  }

  void _showSheet(Widget sheet) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => sheet,
  );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
    isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight;
    final surfaceBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final post = ref.watch(createPostProvider);
    final userAsync = ref.watch(_currentUserProvider);

    final remaining = _maxChars - post.caption.length;
    final showCounter = remaining < 200;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────────────
              _TopBar(
                isSubmitting: post.isSubmitting,
                hasContent: post.hasContent,
                shareScale: _shareScale,
                onClose: _confirmDiscard,
                onShare: _onShare,
                ext: ext,
              ),

              // ── Upload Progress Bar ────────────────────────────────────────
              if (post.isSubmitting)
                LinearProgressIndicator(
                  value: post.submitProgress,
                  minHeight: 2.5,
                  backgroundColor: ext.surfaceVariant,
                  color: AppColors.primary,
                )
              else
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: ext.outline.withValues(alpha: 0.6),
                ),

              // ── Scrollable content ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: userAsync.when(
                          data: (u) {
                            final avatar =
                            resolveAvatarUrl(u?['avatar_url'] as String?);
                            final displayName =
                                u?['display_name'] as String? ?? 'You';
                            final username = u?['username'] as String?;
                            final isPrivate =
                                u?['is_private'] as bool? ?? false;

                            return _UserRow(
                              avatarUrl: avatar,
                              displayName: displayName,
                              username: username,
                              audience: post.audience,
                              isDark: isDark,
                              isPrivate: isPrivate,
                              onAudienceTap: () => _showSheet(
                                _AudienceSheet(
                                  current: post.audience,
                                  onSelect: (a) => ref
                                      .read(createPostProvider.notifier)
                                      .setAudience(a),
                                ),
                              ),
                            );
                          },
                          loading: () => _UserRow(
                            avatarUrl: null,
                            displayName: '…',
                            username: null,
                            audience: post.audience,
                            isDark: isDark,
                            isPrivate: false,
                            onAudienceTap: () {},
                          ),
                          error: (_, __) => _UserRow(
                            avatarUrl: null,
                            displayName: 'You',
                            username: null,
                            audience: post.audience,
                            isDark: isDark,
                            isPrivate: false,
                            onAudienceTap: () {},
                          ),
                        ),
                      ),

                      // Caption field
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: TextField(
                          controller: _captionCtrl,
                          focusNode: _focusNode,
                          maxLines: null,
                          maxLength: _maxChars,
                          buildCounter: (_,
                              {required currentLength,
                                required isFocused,
                                maxLength}) =>
                          null,
                          style: TextStyle(
                            fontSize: 16.5,
                            height: 1.5,
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: "What's on your mind?",
                            hintStyle: TextStyle(
                              color: ext.textSecondary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => ref
                              .read(createPostProvider.notifier)
                              .updateCaption(v),
                        ),
                      ),

                      // Character counter
                      if (showCounter)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$remaining',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: remaining < 50
                                    ? AppColors.error
                                    : ext.textSecondary,
                              ),
                            ),
                          ),
                        ),

                      // Media strip
                      if (post.media.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _MediaStrip(
                          files: post.media,
                          onAdd: () => ref
                              .read(createPostProvider.notifier)
                              .pickFromGallery(),
                          onRemove: (i) => ref
                              .read(createPostProvider.notifier)
                              .removeMedia(i),
                        ),
                      ],

                      // Inline tag chips
                      if (post.feeling != null || post.location != null) ...[
                        const SizedBox(height: 14),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (post.feeling != null)
                                _TagChip(
                                  label: post.feeling!,
                                  icon: Icons.emoji_emotions_outlined,
                                  color: AppColors.iconYellow,
                                  onRemove: () => ref
                                      .read(createPostProvider.notifier)
                                      .setFeeling(null),
                                ),
                              if (post.location != null)
                                _TagChip(
                                  label: post.location!,
                                  icon: Icons.place_rounded,
                                  color: AppColors.iconRed,
                                  onRemove: () => ref
                                      .read(createPostProvider.notifier)
                                      .setLocation(null),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Bottom bar ─────────────────────────────────────────────────
              if (!post.isSubmitting) ...[
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: ext.outline.withValues(alpha: 0.6),
                ),
                _BottomActionBar(
                  surfaceBg: surfaceBg,
                  ext: ext,
                  onPhoto: () => ref
                      .read(createPostProvider.notifier)
                      .pickFromGallery(),
                  onCamera: () => ref
                      .read(createPostProvider.notifier)
                      .pickFromCamera(),
                  onFeeling: () => _showSheet(_FeelingSheet(
                    current: post.feeling,
                    onSelect: (f) => ref
                        .read(createPostProvider.notifier)
                        .setFeeling(f),
                  )),
                  onLocation: () => _showSheet(_LocationSheet(
                    current: post.location,
                    onConfirm: (l) => ref
                        .read(createPostProvider.notifier)
                        .setLocation(l),
                  )),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TOP BAR
// ═════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isSubmitting,
    required this.hasContent,
    required this.shareScale,
    required this.onClose,
    required this.onShare,
    required this.ext,
  });

  final bool isSubmitting;
  final bool hasContent;
  final Animation<double> shareScale;
  final VoidCallback onClose;
  final VoidCallback onShare;
  final AppColorExtension ext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // ── Close ──────────────────────────────────────────────────────────
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 26, color: ext.textPrimary),
            tooltip: 'Discard',
            splashRadius: 20,
          ),

          // ── Title ─────────────────────────────────────────────────────────
          Expanded(
            child: Text(
              'Create Post',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ext.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // ── Share ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ScaleTransition(
              scale: shareScale,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: hasContent ? 1.0 : 0.40,
                child: GestureDetector(
                  onTap: (hasContent && !isSubmitting) ? onShare : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: hasContent
                          ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: hasContent ? null : AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  USER ROW
// ═════════════════════════════════════════════════════════════════════════════

class _UserRow extends StatelessWidget {
  const _UserRow({
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
        // Avatar + gradient ring
        Container(
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: ringBg),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: cs.primaryContainer,
              backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Icon(Icons.person, size: 22, color: cs.onPrimaryContainer)
                  : null,
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
                  Flexible(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ext.textPrimary,
                      ),
                    ),
                  ),
                  if (isPrivate) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.lock_outline_rounded,
                        size: 14, color: ext.textSecondary),
                  ],
                ],
              ),
              if (username != null) ...[
                const SizedBox(height: 1),
                Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: ext.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              // Audience pill
              GestureDetector(
                onTap: onAudienceTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: ext.surfaceVariant,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: ext.outline.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(audience.icon, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        audience.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 14, color: AppColors.primary),
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

// ═════════════════════════════════════════════════════════════════════════════
//  MEDIA STRIP
// ═════════════════════════════════════════════════════════════════════════════

class _MediaStrip extends StatelessWidget {
  const _MediaStrip({
    required this.files,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> files;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: files.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == files.length) {
            return GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  color: ext.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ext.outline.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add more',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(files[i].path),
                  width: 100,
                  height: 118,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ),
              if (files.length > 1)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TAG CHIP
// ═════════════════════════════════════════════════════════════════════════════

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onRemove,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                size: 14, color: color.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  BOTTOM ACTION BAR
// ═════════════════════════════════════════════════════════════════════════════

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.surfaceBg,
    required this.ext,
    required this.onPhoto,
    required this.onCamera,
    required this.onFeeling,
    required this.onLocation,
  });

  final Color surfaceBg;
  final AppColorExtension ext;
  final VoidCallback onPhoto;
  final VoidCallback onCamera;
  final VoidCallback onFeeling;
  final VoidCallback onLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surfaceBg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _ActionBtn(
            icon: Icons.photo_library_outlined,
            label: 'Photo',
            color: AppColors.iconGreen,
            onTap: onPhoto,
            ext: ext,
          ),
          _ActionBtn(
            icon: Icons.camera_alt_outlined,
            label: 'Camera',
            color: AppColors.iconBlue,
            onTap: onCamera,
            ext: ext,
          ),
          _ActionBtn(
            icon: Icons.emoji_emotions_outlined,
            label: 'Feeling',
            color: AppColors.iconYellow,
            onTap: onFeeling,
            ext: ext,
          ),
          _ActionBtn(
            icon: Icons.place_outlined,
            label: 'Location',
            color: AppColors.iconRed,
            onTap: onLocation,
            ext: ext,
          ),
          _ActionBtn(
            icon: Icons.person_add_alt_1_outlined,
            label: 'Tag',
            color: AppColors.iconPurple,
            onTap: () {}, // TODO: Tag people
            ext: ext,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.ext,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final AppColorExtension ext;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 23),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: ext.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  AUDIENCE SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _AudienceSheet extends ConsumerWidget {
  const _AudienceSheet({
    required this.current,
    required this.onSelect,
  });

  final PostAudience current;
  final void Function(PostAudience) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _BottomSheetShell(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Post audience',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ext.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Who can see your post?',
            style: TextStyle(fontSize: 13, color: ext.textSecondary),
          ),
          const SizedBox(height: 16),
          ...PostAudience.values.map((a) => _AudienceOption(
            audience: a,
            isSelected: a == current,
            ext: ext,
            onTap: () {
              onSelect(a);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AudienceOption extends StatelessWidget {
  const _AudienceOption({
    required this.audience,
    required this.isSelected,
    required this.ext,
    required this.onTap,
  });

  final PostAudience audience;
  final bool isSelected;
  final AppColorExtension ext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : ext.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  audience.icon,
                  color: isSelected ? AppColors.primary : ext.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audience.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ext.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      audience.description,
                      style:
                      TextStyle(fontSize: 12, color: ext.textSecondary),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                    key: ValueKey('checked'),
                    color: AppColors.primary,
                    size: 22)
                    : const SizedBox.shrink(key: ValueKey('unchecked')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  FEELING SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _FeelingSheet extends StatelessWidget {
  const _FeelingSheet({required this.current, required this.onSelect});

  final String? current;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _BottomSheetShell(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ext.textPrimary,
                ),
              ),
              const Spacer(),
              if (current != null)
                TextButton(
                  onPressed: () {
                    onSelect(null);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.error),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _feelings.map((f) {
              final label = '${f.$1} ${f.$2}';
              final selected = label == current;
              return GestureDetector(
                onTap: () {
                  onSelect(label);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.iconYellow.withValues(alpha: 0.15)
                        : ext.surfaceVariant,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? AppColors.iconYellow
                          : ext.outline.withValues(alpha: 0.5),
                      width: selected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected
                          ? AppColors.iconYellow
                          : ext.textPrimary,
                    ),
                  ),
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

// ═════════════════════════════════════════════════════════════════════════════
//  LOCATION SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _LocationSheet extends StatefulWidget {
  const _LocationSheet({required this.current, required this.onConfirm});

  final String? current;
  final void Function(String?) onConfirm;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _BottomSheetShell(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ext.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: TextStyle(color: ext.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search or type a location…',
                hintStyle: TextStyle(color: ext.textSecondary),
                prefixIcon: const Icon(Icons.place_outlined,
                    color: AppColors.iconRed),
                filled: true,
                fillColor: ext.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.current != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onConfirm(null);
                        Navigator.pop(context);
                      },
                      child: const Text('Remove'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final val = _ctrl.text.trim();
                      widget.onConfirm(val.isEmpty ? null : val);
                      Navigator.pop(context);
                    },
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  DISCARD SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _DiscardSheet extends StatelessWidget {
  const _DiscardSheet({required this.onDiscard});
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _BottomSheetShell(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🗑️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Discard post?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ext.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your draft will be lost if you leave now.',
            style: TextStyle(fontSize: 14, color: ext.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDiscard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Discard',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Keep editing',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHARED BOTTOM SHEET SHELL
// ═════════════════════════════════════════════════════════════════════════════

class _BottomSheetShell extends StatelessWidget {
  const _BottomSheetShell({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: ext.outline.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}