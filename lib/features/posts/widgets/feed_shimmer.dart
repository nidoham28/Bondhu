import 'package:bondhu/features/stories/widgets/stories_shimmer.dart'; // Reuses the Shimmer wrapper
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

/// Shimmer placeholder that mimics a PostCard exactly.
class PostCardShimmer extends StatelessWidget {
  const PostCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final _ = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              const ShimmerBox(width: 36, height: 36, shape: BoxShape.circle),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 120, height: 12),
                  const SizedBox(height: 6),
                  ShimmerBox(width: 80, height: 10),
                ],
              ),
            ],
          ),
        ),
        // Media
        const ShimmerBox(
          width: double.infinity,
          height: 360, // Approximate square aspect ratio
          borderRadius: BorderRadius.zero,
        ),
        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ShimmerBox(width: 24, height: 24, shape: BoxShape.circle),
                  const SizedBox(width: 16),
                  ShimmerBox(width: 24, height: 24, shape: BoxShape.circle),
                  const SizedBox(width: 16),
                  ShimmerBox(width: 24, height: 24, shape: BoxShape.circle),
                ],
              ),
              ShimmerBox(width: 24, height: 24, shape: BoxShape.circle),
            ],
          ),
        ),
        // Caption
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: double.infinity, height: 10),
              SizedBox(height: 8),
              ShimmerBox(width: 200, height: 10),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.4,
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
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