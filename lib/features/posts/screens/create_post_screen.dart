import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/posts/providers/create_post_provider.dart';
import 'package:bondhu/features/posts/widgets/audience_sheet.dart';
import 'package:bondhu/features/posts/widgets/bottom_action_bar.dart';
import 'package:bondhu/features/posts/widgets/discard_sheet.dart';
import 'package:bondhu/features/posts/widgets/feeling_sheet.dart';
import 'package:bondhu/features/posts/widgets/location_sheet.dart';
import 'package:bondhu/features/posts/widgets/media_strip.dart';
import 'package:bondhu/features/posts/widgets/tag_chip.dart';
import 'package:bondhu/features/posts/widgets/top_bar.dart';
import 'package:bondhu/features/posts/widgets/user_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _focusNode.dispose();
    _shareAnim.dispose();
    ref.invalidate(createPostProvider);
    super.dispose();
  }

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
    _showSheet(DiscardSheet(
      onDiscard: () {
        Navigator.of(context)
          ..pop()
          ..pop();
      },
    ));
  }

  void _showSheet(Widget sheet) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => sheet,
  );

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight;
    final surfaceBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final post = ref.watch(createPostProvider);
    final userAsync = ref.watch(currentUserProvider);

    final remaining = _maxChars - post.caption.length;
    final showCounter = remaining < 200;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              TopBar(
                isSubmitting: post.isSubmitting,
                hasContent: post.hasContent,
                shareScale: _shareScale,
                onClose: _confirmDiscard,
                onShare: _onShare,
              ),
              if (post.isSubmitting)
                LinearProgressIndicator(
                  value: post.submitProgress,
                  minHeight: 2.5,
                  backgroundColor: ext.surfaceVariant,
                  color: AppColors.primary,
                )
              else
                Divider(height: 1, thickness: 0.5, color: ext.outline.withValues(alpha: 0.6)),

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: userAsync.when(
                          data: (u) => UserRow(
                            avatarUrl: resolveAvatarUrl(u?['avatar_url'] as String?),
                            displayName: u?['display_name'] as String? ?? 'You',
                            username: u?['username'] as String?,
                            audience: post.audience,
                            isDark: isDark,
                            isPrivate: u?['is_private'] as bool? ?? false,
                            onAudienceTap: () => _showSheet(AudienceSheet(
                              current: post.audience,
                              onSelect: (a) => ref.read(createPostProvider.notifier).setAudience(a),
                            )),
                          ),
                          loading: () => UserRow(
                            avatarUrl: null, displayName: '…', username: null,
                            audience: post.audience, isDark: isDark, isPrivate: false, onAudienceTap: () {},
                          ),
                          error: (_, _) => UserRow(
                            avatarUrl: null, displayName: 'You', username: null,
                            audience: post.audience, isDark: isDark, isPrivate: false, onAudienceTap: () {},
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: TextField(
                          controller: _captionCtrl,
                          focusNode: _focusNode,
                          maxLines: null,
                          maxLength: _maxChars,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          style: TextStyle(fontSize: 16.5, height: 1.5, color: ext.textPrimary, fontWeight: FontWeight.w400),
                          decoration: InputDecoration(
                            hintText: "What's on your mind?",
                            hintStyle: TextStyle(color: ext.textSecondary, fontSize: 16.5, fontWeight: FontWeight.w400),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => ref.read(createPostProvider.notifier).updateCaption(v),
                        ),
                      ),
                      if (showCounter)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('$remaining', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: remaining < 50 ? AppColors.error : ext.textSecondary)),
                          ),
                        ),
                      if (post.media.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        MediaStrip(
                          files: post.media,
                          onAdd: () => ref.read(createPostProvider.notifier).pickFromGallery(),
                          onRemove: (i) => ref.read(createPostProvider.notifier).removeMedia(i),
                        ),
                      ],
                      if (post.feeling != null || post.location != null) ...[
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (post.feeling != null)
                                TagChip(
                                  label: post.feeling!,
                                  icon: Icons.emoji_emotions_outlined,
                                  color: AppColors.iconYellow,
                                  onRemove: () => ref.read(createPostProvider.notifier).setFeeling(null),
                                ),
                              if (post.location != null)
                                TagChip(
                                  label: post.location!,
                                  icon: Icons.place_rounded,
                                  color: AppColors.iconRed,
                                  onRemove: () => ref.read(createPostProvider.notifier).setLocation(null),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!post.isSubmitting) ...[
                Divider(height: 1, thickness: 0.5, color: ext.outline.withValues(alpha: 0.6)),
                BottomActionBar(
                  surfaceBg: surfaceBg,
                  onPhoto: () => ref.read(createPostProvider.notifier).pickFromGallery(),
                  onCamera: () => ref.read(createPostProvider.notifier).pickFromCamera(),
                  onFeeling: () => _showSheet(FeelingSheet(
                    current: post.feeling,
                    onSelect: (f) => ref.read(createPostProvider.notifier).setFeeling(f),
                  )),
                  onLocation: () => _showSheet(LocationSheet(
                    current: post.location,
                    onConfirm: (l) => ref.read(createPostProvider.notifier).setLocation(l),
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