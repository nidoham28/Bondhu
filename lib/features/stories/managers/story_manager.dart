import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bondhu/features/stories/models/story_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final storyManagerProvider =
    AsyncNotifierProvider<StoryManager, StoryState>(StoryManager.new);

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class StoryState {
  final List<StoryModel> stories;
  final Set<String> seenStoryIds;
  final List<StoryModel> myActiveStories;

  const StoryState({
    this.stories = const [],
    this.seenStoryIds = const {},
    this.myActiveStories = const [],
  });

  StoryState copyWith({
    List<StoryModel>? stories,
    Set<String>? seenStoryIds,
    List<StoryModel>? myActiveStories,
  }) =>
      StoryState(
        stories: stories ?? this.stories,
        seenStoryIds: seenStoryIds ?? this.seenStoryIds,
        myActiveStories: myActiveStories ?? this.myActiveStories,
      );

  /// ID that identifies the upload placeholder — never a real story.
  static const placeholderId = 'your-story-placeholder';

  /// All real stories (own + others) — excludes the upload placeholder.
  List<StoryModel> get viewableStories => stories
      .where((s) => s.id != placeholderId && s.storyImageUrl != null)
      .toList();

  bool get hasMyActiveStories => myActiveStories.isNotEmpty;

  /// Unseen count for OTHER users' stories only (excludes own stories).
  int get unseenCount {
    final ownIds = myActiveStories.map((s) => s.id).toSet();
    return stories
        .where((s) =>
            s.id != placeholderId &&
            !ownIds.contains(s.id) &&
            !s.hasSeen)
        .length;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StoryManager
// ─────────────────────────────────────────────────────────────────────────────

class StoryManager extends AsyncNotifier<StoryState> {
  late final SupabaseClient _db;
  RealtimeChannel? _realtimeChannel;

  @override
  Future<StoryState> build() async {
    _db = Supabase.instance.client;
    ref.onDispose(_disposeRealtime);
    return _loadState();
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadState);
  }

  Future<void> markAsSeen(String storyId) async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    final current = state.valueOrNull;
    if (current == null) return;
    if (current.seenStoryIds.contains(storyId)) return;

    final idx = current.stories.indexWhere((s) => s.id == storyId);
    if (idx == -1) return;

    final updatedStories = List<StoryModel>.from(current.stories);
    updatedStories[idx] = updatedStories[idx].copyWith(hasSeen: true);

    state = AsyncData(current.copyWith(
      stories: updatedStories,
      seenStoryIds: {...current.seenStoryIds, storyId},
    ));

    try {
      await _db.rpc('record_story_view', params: {
        'p_story_id': storyId,
        'p_user_id': user.id,
      });
    } catch (e) {
      debugPrint('[StoryManager] markAsSeen RPC failed: $e');
      state = AsyncData(current); // Rollback
    }
  }

  void subscribeToRealtime() {
    _disposeRealtime();
    _realtimeChannel = _db
        .channel('public:stories:realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'stories',
          callback: (_) => _silentRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'stories',
          callback: (_) => _silentRefresh(),
        )
        .subscribe();
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  Future<StoryState> _loadState() async {
    final user = _db.auth.currentUser;
    if (user == null) return const StoryState();

    try {
      final response = await _db.functions.invoke('get-stories');

      if (response.status != 200) {
        throw Exception(
            'get-stories error ${response.status}: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      return _parseResponse(data, user.id);
    } catch (e) {
      debugPrint('[StoryManager] _loadState error: $e');
      return _fallbackState(user.id);
    }
  }

  StoryState _parseResponse(Map<String, dynamic> data, String userId) {
    final rawStories = data['stories'] as List<dynamic>? ?? [];

    // Parse everything from the API
    final allStories = rawStories
        .map((e) => StoryModel.fromJson(e as Map<String, dynamic>, userId))
        .toList();

    // Keep original references (with isYourStory = true) for the viewer
    final myActiveStories =
        allStories.where((s) => s.isYourStory).toList();

    final seenStoryIds = allStories
        .where((s) => s.hasSeen)
        .map((s) => s.id)
        .toSet();

    // ── Build the "Add Story" placeholder (index 0) ──
    // Only this one item has isYourStory = true.
    String? avatarUrl;
    String username = 'you';
    String displayName = 'Your Story';

    if (myActiveStories.isNotEmpty) {
      avatarUrl = myActiveStories.first.profileImageUrl;
      username = myActiveStories.first.username;
      displayName = myActiveStories.first.displayName;
    }

    final placeholder = StoryModel(
      id: StoryState.placeholderId,
      userId: userId,
      username: username,
      displayName: displayName,
      profileImageUrl: avatarUrl,
      isYourStory: true,
      hasSeen: true,
      timestamp: DateTime.now(),
    );

    // ── Strip isYourStory from real stories ──
    // The user's own real stories must render like normal story circles,
    // NOT as extra "Your Story" circles. Only the placeholder keeps the flag.
    final displayStories = allStories.map((s) {
      if (s.isYourStory) {
        return s.copyWith(isYourStory: false);
      }
      return s;
    }).toList();

    return StoryState(
      stories: [placeholder, ...displayStories],
      seenStoryIds: seenStoryIds,
      myActiveStories: myActiveStories,
    );
  }

  StoryState _fallbackState(String userId) {
    final placeholder = StoryModel(
      id: StoryState.placeholderId,
      userId: userId,
      username: 'you',
      displayName: 'Your Story',
      isYourStory: true,
      hasSeen: true,
      timestamp: DateTime.now(),
    );
    return StoryState(stories: [placeholder]);
  }

  Future<void> _silentRefresh() async {
    try {
      state = AsyncData(await _loadState());
    } catch (e) {
      debugPrint('[StoryManager] Silent refresh failed: $e');
    }
  }

  void _disposeRealtime() {
    if (_realtimeChannel != null) {
      _db.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }
}