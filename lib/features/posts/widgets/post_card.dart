import 'dart:ui';
import 'package:bondhu/features/posts/models/feed_models.dart';
import 'package:bondhu/features/reactions/models/reaction_model.dart';
import 'package:bondhu/utils/feed_utils.dart';
import 'package:bondhu/utils/reaction_utils.dart'; // Ensure this exports the Reactions class
import 'package:bondhu/features/stories/widgets/stories_shimmer.dart'; // Added for Shimmer
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PostCard — top-level card; const-safe header/media/footer split
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
  bool _isSaved = false;
  bool _showHeart = false;

  late final AnimationController _heartController;
  late final Animation<double> _heartScale;
  late final Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeOut));

    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartController);

    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showHeart = false);
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.lightImpact();
    // Double-tap always triggers 'love' (Instagram behavior).
    if (widget.reactionState.userReaction != 'love') {
      widget.onReact('love');
    }
    if (!_showHeart) {
      setState(() => _showHeart = true);
      _heartController.forward(from: 0.0);
    }
  }

  // FIX: If currently reacted, un-react. If un-reacted, ALWAYS default to 'love'.
  void _toggleLike() {
    HapticFeedback.selectionClick();
    final current = widget.reactionState.userReaction;
    // If null, passes 'love'. If 'like', passes 'like' (which notifier turns to null).
    widget.onReact(current ?? Reactions.defaultKey);
  }

  void _toggleSave() {
    HapticFeedback.selectionClick();
    setState(() => _isSaved = !_isSaved);
    widget.onSaveTap?.call();
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
            _Header(
              post: post,
              onProfileTap: widget.onProfileTap,
              onMoreTap: widget.onMoreTap,
            ),
            if (post.mediaUrls.isNotEmpty)
              _MediaSection(
                mediaUrls: post.mediaUrls,
                currentPage: _currentPage,
                showHeart: _showHeart,
                heartScale: _heartScale,
                heartOpacity: _heartOpacity,
                onDoubleTap: _handleDoubleTap,
                onPageChanged: (i) => setState(() => _currentPage = i),
              ),
            _ActionsRow(
              reactionState: widget.reactionState,
              isSaved: _isSaved,
              onLikeTap: _toggleLike,
              onLongLikeTap: _showReactionPopover,
              onCommentTap: widget.onCommentTap,
              onShareTap: widget.onShareTap,
              onSaveTap: _toggleSave,
            ),
            _CaptionSection(
              post: post,
              reactionState: widget.reactionState,
            ),
            const SizedBox(height: 8),
            Divider(
              height: 1,
              thickness: 0.4,
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Post post;
  final VoidCallback? onProfileTap;
  final VoidCallback? onMoreTap;

  const _Header({required this.post, this.onProfileTap, this.onMoreTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: _GradientAvatar(
              avatarUrl: post.author.avatarUrl,
              hasUnseenStory: false,
              radius: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onProfileTap,
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
                            fontSize: 13.5,
                            letterSpacing: -0.1,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (post.author.isVerified) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.verified_rounded,
                            size: 13, color: Color(0xFF0095F6)),
                      ],
                      if (post.sponsored) ...[
                        const SizedBox(width: 6),
                        const _SponsoredBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  if (post.location != null)
                    Text(
                      post.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Text(
                          FeedUtils.timeAgo(post.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _audienceIcon(post.audience),
                          size: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
//  Gradient Avatar Ring
// ─────────────────────────────────────────────────────────────────────────────

class _GradientAvatar extends StatelessWidget {
  final String? avatarUrl;
  final bool hasUnseenStory;
  final double radius;

  const _GradientAvatar({
    this.avatarUrl,
    required this.hasUnseenStory,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ringSize = radius * 2 + (hasUnseenStory ? 5 : 0);

    return Container(
      width: ringSize,
      height: ringSize,
      decoration: hasUnseenStory
          ? const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
            Color(0xFF515BD4),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      )
          : null,
      padding: hasUnseenStory ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        backgroundImage:
        avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
        child: avatarUrl == null
            ? Icon(Icons.person_rounded,
            color: theme.colorScheme.onSurfaceVariant, size: radius)
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Media Section
// ─────────────────────────────────────────────────────────────────────────────

class _MediaSection extends StatelessWidget {
  final List<String> mediaUrls;
  final int currentPage;
  final bool showHeart;
  final Animation<double> heartScale;
  final Animation<double> heartOpacity;
  final VoidCallback onDoubleTap;
  final ValueChanged<int> onPageChanged;

  const _MediaSection({
    required this.mediaUrls,
    required this.currentPage,
    required this.showHeart,
    required this.heartScale,
    required this.heartOpacity,
    required this.onDoubleTap,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onDoubleTap: onDoubleTap,
          child: SizedBox(
            width: screenWidth,
            height: screenWidth,
            child: PageView.builder(
              itemCount: mediaUrls.length,
              onPageChanged: onPageChanged,
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: mediaUrls[i],
                width: screenWidth,
                height: screenWidth,
                fit: BoxFit.cover,
                placeholder: (_, _) => const _MediaPlaceholder(),
                errorWidget: (_, _, _) => const _MediaError(),
              ),
            ),
          ),
        ),
        if (showHeart)
          AnimatedBuilder(
            animation: heartScale,
            builder: (_, _) => Opacity(
              opacity: heartOpacity.value,
              child: Transform.scale(
                scale: heartScale.value,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 90,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 20)],
                ),
              ),
            ),
          ),
        if (mediaUrls.length > 1)
          Positioned(
            bottom: 12,
            child:
            _DotIndicator(count: mediaUrls.length, current: currentPage),
          ),
        if (mediaUrls.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: _CounterPill(
                current: currentPage + 1, total: mediaUrls.length),
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
    // FIX: Replaced flat color with Shimmer effect
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
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withOpacity(0.4),
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
          color: active
              ? const Color(0xFF0095F6)
              : Colors.white.withOpacity(0.6),
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
//  Actions Row
// ─────────────────────────────────────────────────────────────────────────────

class _ActionsRow extends StatelessWidget {
  final PostReactionState reactionState;
  final bool isSaved;
  final VoidCallback onLikeTap;
  final void Function(BuildContext ctx) onLongLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback onSaveTap;

  const _ActionsRow({
    required this.reactionState,
    required this.isSaved,
    required this.onLikeTap,
    required this.onLongLikeTap,
    this.onCommentTap,
    this.onShareTap,
    required this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Builder(
                builder: (btnCtx) => _AnimatedReactButton(
                  reactionState: reactionState,
                  onTap: onLikeTap,
                  onLongPress: () => onLongLikeTap(btnCtx),
                ),
              ),
              _TapScaleButton(
                onTap: onCommentTap ?? () {},
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.chat_bubble_outline_rounded,
                      color: theme.colorScheme.onSurface, size: 24),
                ),
              ),
              _TapScaleButton(
                onTap: onShareTap ?? () {},
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.near_me_outlined,
                      color: theme.colorScheme.onSurface, size: 23),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onSaveTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  key: ValueKey(isSaved),
                  color: theme.colorScheme.onSurface,
                  size: 26,
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
//  Animated React Button
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

    // Bounce only when landing on a reaction, not when removing.
    if (newReaction != null && newReaction != oldReaction) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reaction = widget.reactionState.userReaction;
    final isActive = reaction != null;

    // FIX: Always restore to the default love outline when inactive.
    final iconData = isActive
        ? Reactions.filledIcon(reaction)
        : Reactions.defaultOutlineIcon;

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
//  Caption & Metadata
// ─────────────────────────────────────────────────────────────────────────────

class _CaptionSection extends StatefulWidget {
  final Post post;
  final PostReactionState reactionState;

  const _CaptionSection({required this.post, required this.reactionState});

  @override
  State<_CaptionSection> createState() => _CaptionSectionState();
}

class _CaptionSectionState extends State<_CaptionSection> {
  bool _expanded = false;

  String _buildEmojiRow(Map<String, int> counts) {
    if (counts.isEmpty) return '';
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => Reactions.emoji(e.key)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final rs = widget.reactionState;
    final hasCaption = post.caption != null && post.caption!.isNotEmpty;
    final emojiRow = _buildEmojiRow(rs.reactionCounts);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rs.totalCount > 0)
            Row(
              children: [
                if (emojiRow.isNotEmpty) ...[
                  Text(emojiRow, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                ],
                Text(
                  '${FeedUtils.formatCount(rs.totalCount)} ${rs.totalCount == 1 ? 'reaction' : 'reactions'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          if (hasCaption) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: RichText(
                maxLines: _expanded ? null : 2,
                overflow:
                _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${post.author.username} ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        fontSize: 13.5,
                        letterSpacing: -0.1,
                      ),
                    ),
                    TextSpan(
                      text: post.caption,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                    if (!_expanded &&
                        post.caption != null &&
                        post.caption!.length > 80)
                      TextSpan(
                        text: ' more',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (post.commentCount > 0) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {},
              child: Text(
                'View all ${FeedUtils.formatCount(post.commentCount)} comments',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            FeedUtils.timeAgo(post.createdAt).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reaction Popover
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
//  Tap Scale Button
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