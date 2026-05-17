import 'package:flutter/material.dart';

class StoryAvatar extends StatelessWidget {
  final String? imageUrl;
  final bool hasSeen;
  final double radius;

  const StoryAvatar({
    super.key,
    this.imageUrl,
    this.hasSeen = false,
    this.radius = 30,
  });

  static const _igGradient = LinearGradient(
    colors: [
      Color(0xFFF09433),
      Color(0xFFE6683C),
      Color(0xFFDC2743),
      Color(0xFFCC2366),
      Color(0xFFBC1888),
    ],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showGradient = !hasSeen;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: showGradient
            ? _igGradient
            : LinearGradient(colors: [
          theme.colorScheme.outlineVariant,
          theme.colorScheme.outlineVariant,
        ]),
      ),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        // ClipOval ensures the image is always a perfect circle
        child: ClipOval(
          child: Container(
            width: radius * 2,
            height: radius * 2,
            color: theme.colorScheme.surfaceContainerHighest,
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              // Show icon if image fails to load
              errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(theme),
            )
            // Show icon if no image URL provided (No text!)
                : _buildFallbackIcon(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Icon(
      Icons.person_rounded,
      color: theme.colorScheme.onSurfaceVariant,
      size: radius * 1.1,
    );
  }
}