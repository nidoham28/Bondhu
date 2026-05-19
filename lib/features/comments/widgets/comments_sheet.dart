// lib/features/comments/widgets/comments_sheet.dart

import 'dart:ui';

import 'package:bondhu/features/comments/models/comment_model.dart';
import 'package:bondhu/features/comments/providers/comments_provider.dart';
import 'package:bondhu/services/supabase_service.dart';
import 'package:bondhu/utils/feed_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Public entry-point
// ─────────────────────────────────────────────────────────────────────────────

void showCommentsSheet(BuildContext context, String postId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => CommentsSheet(postId: postId),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  CommentsSheet
// ─────────────────────────────────────────────────────────────────────────────

class CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _scrollController = ScrollController();
  final _inputController  = TextEditingController();
  final _focusNode        = FocusNode();

  bool _isSending = false;
  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentsProvider(widget.postId).notifier).fetchInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.85) {
      ref.read(commentsProvider(widget.postId).notifier).loadMore();
    }
  }

  void _setReplyContext(String commentId, String authorName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToAuthorName = authorName;
    });
    _focusNode.requestFocus();
  }

  void _clearReplyContext() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });
  }

  Future<void> _sendComment() async {
    final body = _inputController.text.trim();
    if (body.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    HapticFeedback.lightImpact();

    try {
      final notifier = ref.read(commentsProvider(widget.postId).notifier);
      if (_replyingToCommentId != null) {
        await notifier.addReply(_replyingToCommentId!, body);
      } else {
        await notifier.addComment(body);
      }

      _inputController.clear();
      _clearReplyContext();
      _focusNode.unfocus();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('INVALID_BODY')) return 'Comment must be 1–1000 characters.';
    if (msg.contains('UNAUTHENTICATED')) return 'Please log in to comment.';
    if (msg.contains('POST_NOT_FOUND')) return 'This post no longer exists.';
    return 'Could not send comment. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final isDark    = theme.brightness == Brightness.dark;
    final state     = ref.watch(commentsProvider(widget.postId));
    final mediaQ    = MediaQuery.of(context);
    final sheetColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        color: sheetColor,
        height: mediaQ.size.height * 0.88,
        child: Column(
          children: [
            _SheetHeader(isDark: isDark, theme: theme),
            const Divider(height: 1, thickness: 0.4),
            Expanded(child: _buildBody(state, theme, isDark)),
            if (_replyingToCommentId != null)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                child: Row(
                  children: [
                    Expanded(child: Text('Replying to $_replyingToAuthorName', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant))),
                    GestureDetector(
                      onTap: _clearReplyContext,
                      child: Icon(Icons.close, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            _CommentInputBar(
              controller: _inputController,
              focusNode: _focusNode,
              isSending: _isSending,
              isDark: isDark,
              theme: theme,
              mediaQ: mediaQ,
              onSend: _sendComment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CommentsState state, ThemeData theme, bool isDark) {
    switch (state.status) {
      case CommentsStatus.initial:
      case CommentsStatus.loading:
        return const _CommentsShimmer();

      case CommentsStatus.error when state.comments.isEmpty:
        return _ErrorState(
          message: state.errorMessage ?? 'Could not load comments.',
          onRetry: () => ref.read(commentsProvider(widget.postId).notifier).fetchInitial(),
          theme: theme,
        );

      default:
        if (state.comments.isEmpty) return _EmptyState(theme: theme);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          itemCount: state.comments.length + 1,
          itemBuilder: (ctx, i) {
            if (i == state.comments.length) {
              return state.status == CommentsStatus.loadingMore
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
                  : const SizedBox(height: 4);
            }
            return _CommentTile(
              comment: state.comments[i],
              postId: widget.postId,
              isDark: isDark,
              theme: theme,
              onReplyTap: (id, name) => _setReplyContext(id, name),
              depth: 0,
            );
          },
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sheet Header
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  const _SheetHeader({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.14),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 10),
        Text('Comments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Comment Tile (Recursive for Threading)
// ─────────────────────────────────────────────────────────────────────────────

class _CommentTile extends ConsumerWidget {
  final Comment comment;
  final String postId;
  final bool isDark;
  final ThemeData theme;
  final int depth;
  final void Function(String commentId, String authorName) onReplyTap;

  const _CommentTile({
    required this.comment,
    required this.postId,
    required this.isDark,
    required this.theme,
    required this.depth,
    required this.onReplyTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = SupabaseService.auth.currentUser?.id;
    final isOwner = currentUserId == comment.author.uid;

    return Padding(
      padding: EdgeInsets.only(
        left: depth > 0 ? 46.0 : 14.0,
        right: 14.0,
        top: 6.0,
        bottom: 6.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommentAvatar(avatarUrl: comment.author.avatarUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.author.displayName,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface),
                              ),
                              if (comment.author.isVerified) ...[
                                const SizedBox(width: 3),
                                const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF0866FF)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            comment.body,
                            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, height: 1.35),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 5),
                      child: Row(
                        children: [
                          Text(FeedUtils.timeAgo(comment.createdAt), style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(width: 12),
                          _ReactionButton(
                            isActive: comment.userReaction == 'LIKE',
                            label: 'Like',
                            onTap: () => ref.read(commentsProvider(postId).notifier).toggleReaction(comment.id, 'LIKE'),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => onReplyTap(comment.id, comment.author.displayName),
                            child: Text('Reply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                          ),
                          if (isOwner) ...[
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _confirmDelete(context, ref),
                              child: Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.error)),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (comment.reactionCounts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: _ReactionSummary(reactionCounts: comment.reactionCounts, total: comment.likesCount),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ── Thread / Replies ─────────────────────────────────
          if (comment.repliesCount > 0 || comment.replies.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (comment.replies.isEmpty && comment.repliesCount > 0)
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                      onPressed: comment.isRepliesLoading
                          ? null
                          : () => ref.read(commentsProvider(postId).notifier).fetchReplies(comment.id),
                      child: comment.isRepliesLoading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('View ${comment.repliesCount} repl${comment.repliesCount == 1 ? 'y' : 'ies'}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                    ),

                  ...comment.replies.map((reply) => _CommentTile(
                    comment: reply,
                    postId: postId,
                    isDark: isDark,
                    theme: theme,
                    onReplyTap: onReplyTap,
                    depth: depth + 1,
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(commentsProvider(postId).notifier).deleteComment(comment.id);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete comment.'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helper UI Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CommentAvatar extends StatelessWidget {
  final String? avatarUrl;
  const _CommentAvatar({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 18,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
      child: avatarUrl == null ? Icon(Icons.person_rounded, color: theme.colorScheme.onSurfaceVariant, size: 18) : null,
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final bool isActive;
  final String label;
  final VoidCallback onTap;

  const _ReactionButton({required this.isActive, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF0866FF) : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ReactionSummary extends StatelessWidget {
  final Map<String, int> reactionCounts;
  final int total;

  const _ReactionSummary({required this.reactionCounts, required this.total});

  @override
  Widget build(BuildContext context) {
    final emojis = <String>[];
    if (reactionCounts.containsKey('LIKE')) emojis.add('👍');
    if (reactionCounts.containsKey('LOVE')) emojis.add('❤️');
    if (reactionCounts.containsKey('HAHA')) emojis.add('😂');
    if (reactionCounts.containsKey('WOW')) emojis.add('😮');
    if (reactionCounts.containsKey('SAD')) emojis.add('😢');
    if (reactionCounts.containsKey('ANGRY')) emojis.add('😡');

    return Row(
      children: [
        Text(emojis.take(3).join(' '), style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(total.toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool isDark;
  final ThemeData theme;
  final MediaQueryData mediaQ;
  final VoidCallback onSend;

  const _CommentInputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isDark,
    required this.theme,
    required this.mediaQ,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = SupabaseService.auth.currentUser?.userMetadata?['avatar_url'] as String?;
    final bottomPad = mediaQ.viewInsets.bottom + mediaQ.padding.bottom + 8;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
              child: avatarUrl == null ? Icon(Icons.person_rounded, color: theme.colorScheme.onSurfaceVariant, size: 17) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Write a comment…',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                    counterText: '',
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(isSending: isSending, onSend: onSend),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  final bool isSending;
  final VoidCallback onSend;
  const _SendButton({required this.isSending, required this.onSend});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween(begin: 1.0, end: 0.86).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onSend(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 38, height: 38,
          decoration: const BoxDecoration(color: Color(0xFF0866FF), shape: BoxShape.circle),
          child: widget.isSending
              ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35)),
          const SizedBox(height: 14),
          Text('No comments yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text('Be the first to comment!', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final ThemeData theme;

  const _ErrorState({required this.message, required this.onRetry, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35)),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            TextButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

class _CommentsShimmer extends StatelessWidget {
  const _CommentsShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05);

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerCircle(size: 36, color: baseColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 120, height: 12, color: baseColor),
                  const SizedBox(height: 6),
                  _ShimmerBox(width: double.infinity, height: 36, color: baseColor, radius: 14),
                  const SizedBox(height: 6),
                  _ShimmerBox(width: 60, height: 10, color: baseColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width; final double height; final Color color; final double radius;
  const _ShimmerBox({required this.width, required this.height, required this.color, this.radius = 6});

  @override
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
  );
}

class _ShimmerCircle extends StatelessWidget {
  final double size; final Color color;
  const _ShimmerCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}