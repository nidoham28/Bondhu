import 'package:bondhu/features/posts/models/feed_models.dart';
import 'package:bondhu/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

class FeedPostsRepository {
  final List<Post> _posts = [];

  String? _nextCursor;
  String? _nextCursorId;
  bool _hasMore = true;
  bool _isFetching = false;

  List<Post> get posts => List.unmodifiable(_posts);
  bool get hasMore => _hasMore;
  bool get isFetching => _isFetching;

  /// Fetches the first page. Used for initial load and pull-to-refresh.
  Future<void> fetchInitialPosts() async {
    _posts.clear();
    _nextCursor = null;
    _nextCursorId = null;
    _hasMore = true;

    await fetchMorePosts();
  }

  /// Fetches the next page of posts via Edge Function
  Future<void> fetchMorePosts() async {
    if (_isFetching || !_hasMore) return;

    _isFetching = true;

    try {
      // Using your SupabaseService.client directly
      final response = await SupabaseService.client.functions.invoke(
        'get-feed',
        body: {
          'cursor': _nextCursor,
          'cursor_id': _nextCursorId,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to load feed: ${response.data}');
      }

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final List<dynamic> jsonPosts = data['data'] ?? [];

      _nextCursor = data['next_cursor'];
      _nextCursorId = data['next_cursor_id'];
      _hasMore = data['has_more'] ?? false;

      final newPosts = jsonPosts.map((json) => Post.fromJson(json)).toList();
      _posts.addAll(newPosts);

    } catch (e) {
      debugPrint('Error fetching feed: $e');
      rethrow;
    } finally {
      _isFetching = false;
    }
  }
}