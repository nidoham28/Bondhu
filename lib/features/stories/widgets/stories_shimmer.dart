import 'package:flutter/material.dart';

/// Reusable shimmer animation wrapper.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = widget.baseColor ?? theme.colorScheme.surfaceContainerHighest;
    final highlight =
        widget.highlightColor ?? theme.colorScheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _animation.value, 0.0),
              end: Alignment(1.0 + _animation.value, 0.0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmer placeholder that mimics the StoriesSection layout.
class StoriesSectionShimmer extends StatelessWidget {
  final int itemCount;

  const StoriesSectionShimmer({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                _ShimmerCircle(),
                SizedBox(height: 6),
                _ShimmerText(width: 48),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer(
      child: Container(
        width: 66, // outer diameter matching StoryAvatar with gradient ring
        height: 66,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ShimmerText extends StatelessWidget {
  final double width;
  const _ShimmerText({required this.width});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer(
      child: Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}