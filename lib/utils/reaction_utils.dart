import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ReactionDef — immutable definition for a single reaction type.
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class ReactionDef {
  final String key;
  final String emoji;
  final String label;
  final IconData filledIcon;
  final IconData outlineIcon;
  final Color activeColor;

  const ReactionDef({
    required this.key,
    required this.emoji,
    required this.label,
    required this.filledIcon,
    required this.outlineIcon,
    required this.activeColor,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reactions — centralized, immutable registry.
//
//  Behaviour contract:
//  ─────────────────────
//  • No reaction       → Love outline ❤️ (default idle state)
//  • User reacts       → Filled icon + activeColor of that reaction
//  • User taps same    → Unreact → back to Love outline
//  • User taps diff    → Switch to new reaction
//
//  Available: love, liked, care, haha, wow, cry, angry
// ─────────────────────────────────────────────────────────────────────────────

final class Reactions {
  Reactions._();

  // ── Master list (order = popover left → right) ────────────────────────────

  static const List<ReactionDef> all = [
    ReactionDef(
      key: 'love',
      emoji: '❤️',
      label: 'Love',
      filledIcon: Icons.favorite_rounded,
      outlineIcon: Icons.favorite_border_rounded,
      activeColor: Color(0xFFED4956),
    ),
    ReactionDef(
      key: 'liked',
      emoji: '👍',
      label: 'Liked',
      filledIcon: Icons.thumb_up_rounded,
      outlineIcon: Icons.thumb_up_outlined,
      activeColor: Color(0xFF0095F6),
    ),
    ReactionDef(
      key: 'care',
      emoji: '🤗',
      label: 'Care',
      filledIcon: Icons.volunteer_activism_rounded,
      outlineIcon: Icons.volunteer_activism_outlined,
      activeColor: Color(0xFFFF9500),
    ),
    ReactionDef(
      key: 'haha',
      emoji: '😂',
      label: 'Haha',
      filledIcon: Icons.emoji_emotions_rounded,
      outlineIcon: Icons.emoji_emotions_outlined,
      activeColor: Color(0xFFFFC800),
    ),
    ReactionDef(
      key: 'wow',
      emoji: '😮',
      label: 'Wow',
      filledIcon: Icons.sentiment_very_satisfied_rounded,
      outlineIcon: Icons.sentiment_very_satisfied_outlined,
      activeColor: Color(0xFFFFB800),
    ),
    ReactionDef(
      key: 'cry',
      emoji: '😢',
      label: 'Cry',
      filledIcon: Icons.sentiment_very_dissatisfied_rounded,
      outlineIcon: Icons.sentiment_very_dissatisfied_outlined,
      activeColor: Color(0xFF5B9BD5),
    ),
    ReactionDef(
      key: 'angry',
      emoji: '😡',
      label: 'Angry',
      filledIcon: Icons.mood_bad_rounded,
      outlineIcon: Icons.mood_bad_outlined,
      activeColor: Color(0xFFE0420A),
    ),
  ];

  // ── Default ───────────────────────────────────────────────────────────────

  static const String defaultKey = 'love';

  // ── O(1) lookup index ─────────────────────────────────────────────────────

  static final Map<String, ReactionDef> _index = {
    for (final r in all) r.key: r,
  };

  // ── Lookup ────────────────────────────────────────────────────────────────

  /// Returns the [ReactionDef] for [key], or null if unknown.
  static ReactionDef? find(String? key) => key != null ? _index[key] : null;

  /// Whether [key] maps to a registered reaction.
  static bool exists(String? key) => key != null && _index.containsKey(key);

  /// Total number of registered reactions.
  static int get count => all.length;

  // ── Default helpers ───────────────────────────────────────────────────────

  /// The default reaction definition (love).
  static ReactionDef get defaultReaction => _index[defaultKey]!;

  /// Outline icon shown when user has no reaction.
  static IconData get defaultOutlineIcon => defaultReaction.outlineIcon;

  /// Active color for the default reaction.
  static Color get defaultActiveColor => defaultReaction.activeColor;

  // ── Per-key accessors (null-safe, fall back to default) ──────────────────

  static IconData filledIcon(String? key) =>
      _index[key]?.filledIcon ?? defaultReaction.filledIcon;

  static IconData outlineIcon(String? key) =>
      _index[key]?.outlineIcon ?? defaultReaction.outlineIcon;

  static Color activeColor(String? key) =>
      _index[key]?.activeColor ?? defaultReaction.activeColor;

  static String emoji(String? key) => _index[key]?.emoji ?? '';

  static String label(String? key) => _index[key]?.label ?? key ?? '';

  // ── Summary helpers ──────────────────────────────────────────────────────

  /// Top [take] emoji strings joined (no spaces), sorted by count descending.
  ///
  /// Example: `"❤️👍🤗"`
  static String topEmojis(Map<String, int> counts, {int take = 3}) {
    if (counts.isEmpty) return '';
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(take)
        .map((e) => emoji(e.key))
        .where((s) => s.isNotEmpty)
        .join();
  }

  /// Single emoji for the most popular reaction.
  static String dominantEmoji(Map<String, int> counts) {
    if (counts.isEmpty) return '';
    final best = counts.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
    );
    return emoji(best.key);
  }

  // ── Toggle ───────────────────────────────────────────────────────────────

  /// Returns the next reaction state:
  /// - same reaction → `null` (unreact → default love outline)
  /// - different / null → [target]
  static String? toggle(String? current, String target) =>
      current == target ? null : target;

  // ── Icon resolver for the main action button ─────────────────────────────

  /// Resolves the icon to display on the primary reaction button.
  ///
  /// - No reaction → love outline
  /// - Reacted     → filled icon of that reaction
  static IconData resolveIcon(String? currentKey) =>
      currentKey != null ? filledIcon(currentKey) : defaultOutlineIcon;

  /// Resolves the color to display on the primary reaction button.
  ///
  /// - No reaction → love red (still tinted for brand consistency)
  /// - Reacted     → activeColor of that reaction
  static Color resolveColor(String? currentKey) =>
      currentKey != null ? activeColor(currentKey) : defaultActiveColor;
}