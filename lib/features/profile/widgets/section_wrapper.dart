import 'package:bondhu/config/theme.dart';
import 'package:flutter/material.dart';

/// Card container for grouping profile section tiles.
class SectionCard extends StatelessWidget {
  final List<Widget> children;

  const SectionCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final ext = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: ext.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ext.outline.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Column(children: children),
    );
  }
}

/// Section wrapper with a title label and card container.
class SectionWrapper extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionWrapper({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SectionCard(children: children),
        ],
      ),
    );
  }
}

/// Thin divider used between tiles inside a [SectionCard].
class ProfileDivider extends StatelessWidget {
  const ProfileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 70,
      color: context.appColors.outline.withValues(alpha: 0.4),
    );
  }
}