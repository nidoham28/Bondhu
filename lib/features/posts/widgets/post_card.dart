import 'package:bondhu/features/posts/models/feed_models.dart';
import 'package:bondhu/utils/feed_utils.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add to pubspec
import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onMoreTap;

  const PostCard({
    super.key,
    required this.post,
    this.onProfileTap,
    this.onLikeTap,
    this.onCommentTap,
    this.onShareTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: post.author.avatarUrl != null
                      ? CachedNetworkImageProvider(post.author.avatarUrl!)
                      : null,
                  child: post.author.avatarUrl == null
                      ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
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
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (post.author.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: Colors.blueAccent),
                        ],
                        if (post.sponsored) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Sponsored', style: TextStyle(fontSize: 9, color: theme.colorScheme.onTertiaryContainer)),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          FeedUtils.timeAgo(post.createdAt),
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 6),
                        Icon(_audienceIcon(post.audience), size: 11, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_horiz_rounded, color: theme.colorScheme.onSurfaceVariant),
                onPressed: onMoreTap,
              ),
            ],
          ),
        ),

        // ── Media Carousel ────────────────────────────────────────
        if (post.mediaUrls.isNotEmpty)
          SizedBox(
            height: MediaQuery.of(context).size.width, // Square aspect ratio
            child: PageView.builder(
              itemCount: post.mediaUrls.length,
              controller: PageController(viewportFraction: 1.0),
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: post.mediaUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: theme.colorScheme.surfaceContainerHighest),
                  errorWidget: (_, _, _) => Icon(Icons.broken_image_rounded, color: theme.colorScheme.error),
                );
              },
            ),
          ),

        // ── Actions ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.favorite_border_rounded, color: theme.colorScheme.onSurface, size: 26),
                    onPressed: onLikeTap,
                  ),
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline_rounded, color: theme.colorScheme.onSurface, size: 24),
                    onPressed: onCommentTap,
                  ),
                  IconButton(
                    icon: Icon(Icons.send_outlined, color: theme.colorScheme.onSurface, size: 22),
                    onPressed: onShareTap,
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.bookmark_border_rounded, color: theme.colorScheme.onSurface, size: 26),
                onPressed: () {}, // Save logic
              ),
            ],
          ),
        ),

        // ── Metrics & Caption ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${FeedUtils.formatCount(post.reactionsCount)} reactions',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface),
              ),
              if (post.caption != null && post.caption!.isNotEmpty) ...[
                const SizedBox(height: 4),
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${post.author.username} ',
                        style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, fontSize: 13),
                      ),
                      TextSpan(
                        text: post.caption,
                        style: TextStyle(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurface, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
              if (post.location != null) ...[
                const SizedBox(height: 2),
                Text(
                  post.location!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${FeedUtils.formatCount(post.commentCount)} comments · ${FeedUtils.formatCount(post.viewsCount)} views',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ],
    );
  }

  IconData _audienceIcon(String audience) {
    switch (audience) {
      case 'PRIVATE': return Icons.lock_outline_rounded;
      case 'FOLLOWERS': return Icons.people_outline_rounded;
      case 'FRIENDS_ONLY': return Icons.group_outlined;
      default: return Icons.public_rounded;
    }
  }
}