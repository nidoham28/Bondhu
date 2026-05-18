import 'package:bondhu/features/stories/widgets/stories_shimmer.dart';
import 'package:flutter/material.dart';

/// A reusable shimmer box that matches the app's shape and color system.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxShape shape;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  }) : assert(shape == BoxShape.rectangle || shape == BoxShape.circle);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double? w = width;
    double? h = height;
    if (shape == BoxShape.circle) {
      w = w ?? h;
      h = h ?? w;
    }

    return Shimmer(
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        ),
      ),
    );
  }
}

/// Shimmer placeholder that mimics a Facebook-style PostCard.
/// Layout order: Header → Caption lines → Media → Summary row → Divider → Action row
class PostCardShimmer extends StatelessWidget {
  const PostCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final mediaHeight = screenWidth * 0.75;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShimmerBox(width: 40, height: 40, shape: BoxShape.circle),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 130, height: 13),
                  SizedBox(height: 5),
                  ShimmerBox(width: 90, height: 11),
                ],
              ),
            ],
          ),
        ),

        // ── Caption lines (Facebook shows text before media) ─
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: double.infinity, height: 13),
              SizedBox(height: 6),
              ShimmerBox(width: double.infinity, height: 13),
              SizedBox(height: 6),
              ShimmerBox(width: 180, height: 13),
            ],
          ),
        ),

        // ── Media (4:3 ratio) ───────────────────────────────
        ShimmerBox(
          width: double.infinity,
          height: mediaHeight,
          borderRadius: BorderRadius.zero,
        ),

        // ── Reaction summary row ────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ShimmerBox(width: 50, height: 13),
                ],
              ),
              ShimmerBox(width: 90, height: 13),
            ],
          ),
        ),

        // ── Thin divider above actions ──────────────────────
        Divider(
          height: 1,
          thickness: 0.4,
          indent: 14,
          endIndent: 14,
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.black.withOpacity(0.10),
        ),

        // ── Action row: Like | Comment | Share ──────────────
        SizedBox(
          height: 44,
          child: Row(
            children: [
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerBox(width: 20, height: 20, shape: BoxShape.circle),
                      SizedBox(width: 6),
                      ShimmerBox(width: 36, height: 12),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                child: VerticalDivider(
                  width: 1,
                  thickness: 0.6,
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.12),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerBox(width: 20, height: 20, shape: BoxShape.circle),
                      SizedBox(width: 6),
                      ShimmerBox(width: 60, height: 12),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                child: VerticalDivider(
                  width: 1,
                  thickness: 0.6,
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.12),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerBox(width: 20, height: 20, shape: BoxShape.circle),
                      SizedBox(width: 6),
                      ShimmerBox(width: 42, height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Thick bottom separator (Facebook card gap) ──────
        Divider(
          height: 6,
          thickness: 6,
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
        ),
      ],
    );
  }
}

/// Sliver wrapper for the feed loading state.
class FeedSliverShimmer extends StatelessWidget {
  final int itemCount;
  const FeedSliverShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => const PostCardShimmer(),
        childCount: itemCount,
      ),
    );
  }
}