import 'package:bondhu/utils/reaction_utils.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Add collection package for deep map equality

@immutable
class PostReactionState {
  final String? userReaction; // e.g. 'love', 'liked', null = un-reacted
  final int totalCount;
  final Map<String, int> reactionCounts;

  const PostReactionState({
    required this.userReaction,
    required this.totalCount,
    required this.reactionCounts,
  });

  // ── Factories ─────────────────────────────────────────────────────────────

  /// Empty initial state with an unmodifiable empty map.
  factory PostReactionState.empty() => const PostReactionState(
    userReaction: null,
    totalCount: 0,
    reactionCounts: {},
  );

  /// Parses backend response.
  /// SANITIZES data: ignores invalid reaction keys to prevent UI crashes.
  factory PostReactionState.fromMap(Map<String, dynamic> map) {
    final rawCounts = (map['reaction_counts'] as Map<String, dynamic>?) ?? {};

    // Filter out any keys not registered in Reactions registry
    final sanitizedCounts = Map<String, int>.fromEntries(
      rawCounts.entries
          .where((e) => Reactions.exists(e.key))
          .map((e) => MapEntry(e.key, (e.value as num).toInt())),
    );

    final rawUserReaction = map['user_reaction'] as String?;
    final sanitizedUserReaction = Reactions.exists(rawUserReaction)
        ? rawUserReaction
        : null;

    return PostReactionState(
      userReaction: sanitizedUserReaction,
      totalCount: (map['total_count'] as num?)?.toInt() ?? 0,
      reactionCounts: Map.unmodifiable(sanitizedCounts),
    );
  }

  // ── Copy-With (Sentinel Pattern) ─────────────────────────────────────────

  static const _unset = Object();

  PostReactionState copyWith({
    Object? userReaction = _unset,
    int? totalCount,
    Map<String, int>? reactionCounts,
  }) {
    return PostReactionState(
      userReaction: identical(userReaction, _unset)
          ? this.userReaction
          : userReaction as String?,
      totalCount: totalCount ?? this.totalCount,
      // Always force unmodifiable to guarantee immutability
      reactionCounts: reactionCounts != null
          ? Map.unmodifiable(reactionCounts)
          : this.reactionCounts,
    );
  }

  // ── Domain Logic: Optimistic Toggle ───────────────────────────────────────

  /// Returns a new state reflecting the toggled reaction.
  /// Use this for instant UI updates before the backend confirms.
  PostReactionState toggleReaction(String targetKey) {
    if (!Reactions.exists(targetKey)) return this; // Ignore invalid keys

    final nextReaction = Reactions.toggle(userReaction, targetKey);
    final nextCounts = Map<String, int>.from(reactionCounts);
    int nextTotal = totalCount;

    if (userReaction == targetKey) {
      // ─── Un-reacting ───
      nextCounts[targetKey] = (nextCounts[targetKey] ?? 1) - 1;
      if (nextCounts[targetKey]! <= 0) nextCounts.remove(targetKey);
      nextTotal--;
    } else if (userReaction == null) {
      // ─── Reacting from null ───
      nextCounts[targetKey] = (nextCounts[targetKey] ?? 0) + 1;
      nextTotal++;
    } else {
      // ─── Switching reaction ───
      // Decrease old
      nextCounts[userReaction!] = (nextCounts[userReaction!] ?? 1) - 1;
      if (nextCounts[userReaction!]! <= 0) nextCounts.remove(userReaction!);
      // Increase new
      nextCounts[targetKey] = (nextCounts[targetKey] ?? 0) + 1;
      // Total count remains the same
    }

    return PostReactionState(
      userReaction: nextReaction,
      totalCount: nextTotal,
      reactionCounts: nextCounts,
    );
  }

  // ── Equality & Hashing ────────────────────────────────────────────────────
  // NOTE: Deep map comparison is required for accurate equality checks
  // in Bloc/Provider/Riverpod to trigger UI rebuilds correctly.

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PostReactionState &&
              other.userReaction == userReaction &&
              other.totalCount == totalCount &&
              const DeepCollectionEquality().equals(other.reactionCounts, reactionCounts);

  @override
  int get hashCode => Object.hash(
    userReaction,
    totalCount,
    const DeepCollectionEquality().hash(reactionCounts),
  );

  @override
  String toString() =>
      'PostReactionState(userReaction: $userReaction, totalCount: $totalCount, counts: $reactionCounts)';
}