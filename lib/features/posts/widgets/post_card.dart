import 'dart:ui';
import 'package:bondhu/features/posts/models/feed_models.dart';
import 'package:bondhu/features/reactions/models/reaction_model.dart';
import 'package:bondhu/features/profile/screens/profile_screen.dart'; // <-- ADDED IMPORT
import 'package:bondhu/utils/feed_utils.dart';
import 'package:bondhu/utils/reaction_utils.dart';
import 'package:bondhu/features/stories/widgets/stories_shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PostCard — Facebook-style layout
//  Structure: Header → Caption → Media → Reaction Summary → Divider → Actions
// ─────────────────────────────────────────────────────────────────────────────

class PostCard extends StatefulWidget {
  final Post post;
  final PostReactionState reactionState;
  final Function(String reactionType) onReact;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onSaveTap;

  const PostCard({
    super.key,
    required this.post,
    required this.reactionState,
    required this.onReact,
    this.onProfileTap,
    this.onCommentTap,
    this.onShareTap,
    this.onMoreTap,
    this.onSaveTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  bool _showDoubleTapReaction = false;

  late final AnimationController _doubleTapController;
  late final Animation<double> _doubleTapScale;
  late final Animation<double> _doubleTapOpacity;

  @override
  void initState() {
    super.initState();
    _doubleTapController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _doubleTapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _doubleTapController, curve: Curves.easeOut));

    _doubleTapOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_doubleTapController);

    _doubleTapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showDoubleTapReaction = false);
      }
    });
  }

  @override
  void dispose() {
    _doubleTapController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.lightImpact();
    if (widget.reactionState.userReaction != Reactions.defaultKey) {
      widget.onReact(Reactions.defaultKey);
    }
    if (!_showDoubleTapReaction) {
      setState(() => _showDoubleTapReaction = true);
      _doubleTapController.forward(from: 0.0);
    }
  }

  void _toggleLike() {
    HapticFeedback.selectionClick();
    final current = widget.reactionState.userReaction;
    widget.onReact(current ?? Reactions.defaultKey);
  }

  void _showReactionPopover(BuildContext buttonCtx) {
    HapticFeedback.mediumImpact();
    final box = buttonCtx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => _ReactionPopover(
        anchorOffset: offset,
        anchorSize: size,
        onReact: (type) {
          Navigator.pop(context);
          widget.onReact(type);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final post = widget.post;

    return RepaintBoundary(
      child: Container(
        color: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            _Header(
              post: post,
              onProfileTap: widget.onProfileTap,
              onMoreTap: widget.onMoreTap,
            ),

            // 2. Caption — BEFORE media (Facebook convention)
            if (post.caption != null && post.caption!.isNotEmpty)
              _CaptionText(post: post),

            // 3. Media
            if (post.mediaUrls.isNotEmpty)
              _MediaSection(
                mediaUrls: post.mediaUrls,
                currentPage: _currentPage,
                showDoubleTapReaction: _showDoubleTapReaction,
                doubleTapScale: _doubleTapScale,
                doubleTapOpacity: _doubleTapOpacity,
                onDoubleTap: _handleDoubleTap,
                onPageChanged: (i) => setState(() => _currentPage = i),
              ),

            // 4. Reaction + Comment summary row
            _ReactionSummaryRow(
              reactionState: widget.reactionState,
              commentCount: post.commentCount,
              shareCount: post.shareCount,
            ),

            // 5. Divider above actions
            Divider(
              height: 1,
              thickness: 0.4,
              indent: 14,
              endIndent: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.black.withOpacity(0.10),
            ),

            // 6. Action buttons row (Like | Comment | Share)
            _FbActionsRow(
              reactionState: widget.reactionState,
              onLikeTap: _toggleLike,
              onLongLikeTap: _showReactionPopover,
              onCommentTap: widget.onCommentTap,
              onShareTap: widget.onShareTap,
            ),

            // 7. Bottom divider
            Divider(
              height: 1,
              thickness: 6,
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Header — Facebook style: avatar + name + timestamp + audience + follow btn
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Post post;
  final VoidCallback? onProfileTap;
  final VoidCallback? onMoreTap;

  const _Header({required this.post, this.onProfileTap, this.onMoreTap});

  // Navigate directly to the user's profile
  void _navigateToProfile(BuildContext context) {
    final String authorId = post.author.uid; // Adjust property name if your model uses .uid
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(uid: authorId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: _FbAvatar(
              avatarUrl: post.author.avatarUrl,
              radius: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToProfile(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.author.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (post.author.isVerified) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.verified_rounded,
                            size: 14, color: Color(0xFF0866FF)),
                      ],
                      if (post.sponsored) ...[
                        const SizedBox(width: 6),
                        const _SponsoredBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        post.location ?? FeedUtils.timeAgo(post.createdAt),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (post.location == null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '·',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Icon(
                          _audienceIcon(post.audience),
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          _TapScaleButton(
            onTap: onMoreTap ?? () {},
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.more_horiz_rounded,
                  color: theme.colorScheme.onSurface, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  IconData _audienceIcon(String audience) => switch (audience) {
    'PRIVATE' => Icons.lock_outline_rounded,
    'FOLLOWERS' => Icons.people_outline_rounded,
    'FRIENDS_ONLY' => Icons.group_outlined,
    _ => Icons.public_rounded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  Facebook Avatar — with colorful gradient ring
// ─────────────────────────────────────────────────────────────────────────────

class _FbAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const _FbAvatar({this.avatarUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(2.5), // Thickness of the colorful ring
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFFf09433), // Orange
            Color(0xFFe6683c), // Orange-Red
            Color(0xFFdc2743), // Red-Pink
            Color(0xFFcc2366), // Pink
            Color(0xFFbc1888), // Purple
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.surface, // Gap between ring and image
        child: CircleAvatar(
          radius: radius - 2.0, // Slightly smaller to reveal the gap
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          backgroundImage:
          avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
          child: avatarUrl == null
              ? Icon(Icons.person_rounded,
              color: theme.colorScheme.onSurfaceVariant, size: radius)
              : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Caption Text — shown ABOVE media on Facebook
// ─────────────────────────────────────────────────────────────────────────────

class _CaptionText extends StatefulWidget {
  final Post post;
  const _CaptionText({required this.post});

  @override
  State<_CaptionText> createState() => _CaptionTextState();
}

class _CaptionTextState extends State<_CaptionText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = widget.post.caption ?? '';
    final isLong = caption.length > 120;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: GestureDetector(
        onTap: isLong ? () => setState(() => _expanded = !_expanded) : null,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _expanded || !isLong
                    ? caption
                    : '${caption.substring(0, 120)}...',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              if (isLong && !_expanded)
                TextSpan(
                  text: ' See more',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Media Section — unchanged logic, full-width (not square-cropped)
// ─────────────────────────────────────────────────────────────────────────────

class _MediaSection extends StatelessWidget {
  final List<String> mediaUrls;
  final int currentPage;
  final bool showDoubleTapReaction;
  final Animation<double> doubleTapScale;
  final Animation<double> doubleTapOpacity;
  final VoidCallback onDoubleTap;
  final ValueChanged<int> onPageChanged;

  const _MediaSection({
    required this.mediaUrls,
    required this.currentPage,
    required this.showDoubleTapReaction,
    required this.doubleTapScale,
    required this.doubleTapOpacity,
    required this.onDoubleTap,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final mediaHeight = screenWidth * 0.75;

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onDoubleTap: onDoubleTap,
          child: SizedBox(
            width: screenWidth,
            height: mediaHeight,
            child: PageView.builder(
              itemCount: mediaUrls.length,
              onPageChanged: onPageChanged,
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: mediaUrls[i],
                width: screenWidth,
                height: mediaHeight,
                fit: BoxFit.cover,
                placeholder: (_, _) => const _MediaPlaceholder(),
                errorWidget: (_, _, _) => const _MediaError(),
              ),
            ),
          ),
        ),
        if (showDoubleTapReaction)
          AnimatedBuilder(
            animation: doubleTapScale,
            builder: (_, _) => Opacity(
              opacity: doubleTapOpacity.value,
              child: Transform.scale(
                scale: doubleTapScale.value,
                child: Text(
                  Reactions.emoji(Reactions.defaultKey), // 👍 exact emoji from registry
                  style: const TextStyle(
                    fontSize: 65,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 20)],
                  ),
                ),
              ),
            ),
          ),
        if (mediaUrls.length > 1)
          Positioned(
            bottom: 12,
            child: _DotIndicator(count: mediaUrls.length, current: currentPage),
          ),
        if (mediaUrls.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: _CounterPill(current: currentPage + 1, total: mediaUrls.length),
          ),
      ],
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError();

  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Center(
      child: Icon(
        Icons.broken_image_rounded,
        size: 40,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
      ),
    ),
  );
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(count > 10 ? 10 : count, (i) {
      final active = i == current;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: active ? 16 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0866FF) : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    }),
  );
}

class _CounterPill extends StatelessWidget {
  final int current;
  final int total;

  const _CounterPill({required this.current, required this.total});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        color: Colors.black.withOpacity(0.35),
        child: Text(
          '$current/$total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reaction Summary Row — Facebook style:
//  [👍❤️😂] 128  ·  47 comments · 12 shares
// ─────────────────────────────────────────────────────────────────────────────

class _ReactionSummaryRow extends StatelessWidget {
  final PostReactionState reactionState;
  final int commentCount;
  final int? shareCount;

  const _ReactionSummaryRow({
    required this.reactionState,
    required this.commentCount,
    this.shareCount,
  });

  String _topEmojiStack(Map<String, int> counts) {
    if (counts.isEmpty) return '';
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => Reactions.emoji(e.key)).join('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rs = reactionState;
    final hasReactions = rs.totalCount > 0;
    final hasComments = commentCount > 0;
    final hasShares = (shareCount ?? 0) > 0;

    if (!hasReactions && !hasComments && !hasShares) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (hasReactions)
            Row(
              children: [
                Text(
                  _topEmojiStack(rs.reactionCounts),
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(width: 4),
                Text(
                  FeedUtils.formatCount(rs.totalCount),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
          Row(
            children: [
              if (hasComments)
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    '${FeedUtils.formatCount(commentCount)} comment${commentCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (hasComments && hasShares)
                Text(
                  '  ·  ',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (hasShares)
                Text(
                  '${FeedUtils.formatCount(shareCount!)} share${shareCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Facebook Actions Row — Like | Comment | Share as text+icon buttons
// ─────────────────────────────────────────────────────────────────────────────

class _FbActionsRow extends StatelessWidget {
  final PostReactionState reactionState;
  final VoidCallback onLikeTap;
  final void Function(BuildContext ctx) onLongLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;

  const _FbActionsRow({
    required this.reactionState,
    required this.onLikeTap,
    required this.onLongLikeTap,
    this.onCommentTap,
    this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reaction = reactionState.userReaction;
    final isActive = reaction != null;

    final likeColor =
    isActive ? Reactions.activeColor(reaction) : theme.colorScheme.onSurface;
    final likeIcon =
    isActive ? Reactions.filledIcon(reaction) : Reactions.defaultOutlineIcon;
    final likeLabel = isActive ? Reactions.label(reaction) : 'Like';

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Builder(
              builder: (btnCtx) => _FbActionButton(
                icon: likeIcon,
                label: likeLabel,
                color: likeColor,
                onTap: onLikeTap,
                onLongPress: () => onLongLikeTap(btnCtx),
              ),
            ),
          ),
          _VerticalDivider(theme: theme),
          Expanded(
            child: _FbActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Comment',
              color: theme.colorScheme.onSurface,
              onTap: onCommentTap ?? () {},
            ),
          ),
          _VerticalDivider(theme: theme),
          Expanded(
            child: _FbActionButton(
              icon: Icons.reply_rounded,
              label: 'Share',
              color: theme.colorScheme.onSurface,
              onTap: onShareTap ?? () {},
              iconMirror: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final ThemeData theme;
  const _VerticalDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      height: 24,
      child: VerticalDivider(
        width: 1,
        thickness: 0.6,
        color: isDark
            ? Colors.white.withOpacity(0.12)
            : Colors.black.withOpacity(0.12),
      ),
    );
  }
}

class _FbActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool iconMirror;

  const _FbActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.onLongPress,
    this.iconMirror = false,
  });

  @override
  State<_FbActionButton> createState() => _FbActionButtonState();
}

class _FbActionButtonState extends State<_FbActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          height: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform(
                alignment: Alignment.center,
                transform: widget.iconMirror
                    ? (Matrix4.identity()..scale(-1.0, 1.0, 1.0))
                    : Matrix4.identity(),
                child: Icon(widget.icon, size: 20, color: widget.color),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Animated React Button (used via long press popover trigger in ActionsRow)
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedReactButton extends StatefulWidget {
  final PostReactionState reactionState;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AnimatedReactButton({
    required this.reactionState,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_AnimatedReactButton> createState() => _AnimatedReactButtonState();
}

class _AnimatedReactButtonState extends State<_AnimatedReactButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.32), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.32, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_AnimatedReactButton old) {
    super.didUpdateWidget(old);
    final newReaction = widget.reactionState.userReaction;
    final oldReaction = old.reactionState.userReaction;
    if (newReaction != null && newReaction != oldReaction) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reaction = widget.reactionState.userReaction;
    final isActive = reaction != null;
    final iconData =
    isActive ? Reactions.filledIcon(reaction) : Reactions.defaultOutlineIcon;
    final iconColor =
    isActive ? Reactions.activeColor(reaction) : theme.colorScheme.onSurface;
    final iconKey = ValueKey(isActive ? 'on_$reaction' : 'off_default');

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, _) => Transform.scale(
            scale: _scale.value,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(iconData, key: iconKey, color: iconColor, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reaction Popover — unchanged logic
// ─────────────────────────────────────────────────────────────────────────────

class _ReactionPopover extends StatefulWidget {
  final Offset anchorOffset;
  final Size anchorSize;
  final Function(String type) onReact;

  const _ReactionPopover({
    required this.anchorOffset,
    required this.anchorSize,
    required this.onReact,
  });

  @override
  State<_ReactionPopover> createState() => _ReactionPopoverState();
}

class _ReactionPopoverState extends State<_ReactionPopover>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  String? _hovered;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenW = MediaQuery.of(context).size.width;

    const popoverWidth = 280.0;
    const popoverHeight = 56.0;
    double left = widget.anchorOffset.dx - 8;
    if (left + popoverWidth > screenW - 12) {
      left = screenW - popoverWidth - 12;
    }
    final top = widget.anchorOffset.dy - popoverHeight - 12;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: popoverWidth,
                  height: popoverHeight,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.5 : 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: Reactions.all.map((reaction) {
                      final isHovered = _hovered == reaction.key;
                      return GestureDetector(
                        onTap: () => widget.onReact(reaction.key),
                        child: MouseRegion(
                          onEnter: (_) =>
                              setState(() => _hovered = reaction.key),
                          onExit: (_) => setState(() => _hovered = null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            transform: isHovered
                                ? (Matrix4.identity()
                              ..scale(1.3)
                              ..translate(0.0, -4.0))
                                : Matrix4.identity(),
                            child: Text(
                              reaction.emoji,
                              style: TextStyle(
                                fontSize: isHovered ? 30 : 26,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Sponsored Badge
// ─────────────────────────────────────────────────────────────────────────────

class _SponsoredBadge extends StatelessWidget {
  const _SponsoredBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Sponsored',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSecondaryContainer,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tap Scale Button (generic reusable)
// ─────────────────────────────────────────────────────────────────────────────

class _TapScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TapScaleButton({required this.child, required this.onTap});

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.82)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}