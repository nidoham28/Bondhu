import 'package:bondhu/features/posts/models/feed_models.dart';
import 'package:bondhu/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

/// Immutable cursor state for pagination.
@immutable
class _PageCursor {
  final String? value;
  final String? id;

  const _PageCursor({this.value, this.id});
}

class FeedPostsRepository {
  _PageCursor _cursor = const _PageCursor();
  bool _hasMore = true;
  bool _isFetching = false;

  bool get hasMore => _hasMore;
  bool get isFetching => _isFetching;

  /// Fetches the first page. Used for initial load and pull-to-refresh.
  /// Returns the new posts so the Provider can update its state.
  Future<List<Post>> fetchInitialPosts() async {
    _cursor = const _PageCursor(); // Reset cursor to page 1
    _hasMore = true;
    return _fetchPage();
  }

  /// Fetches the next page of posts via Edge Function.
  /// Returns only the NEW posts so the Provider can append them.
  Future<List<Post>> fetchMorePosts() async {
    return _fetchPage();
  }

  // ── Private API Caller ──────────────────────────────────────────────────

  Future<List<Post>> _fetchPage() async {
    // Guard against duplicate requests
    if (_isFetching || !_hasMore) return [];

    _isFetching = true;

    try {
      final response = await SupabaseService.client.functions.invoke(
        'get-feed',
        body: {
          'cursor': _cursor.value,
          'cursor_id': _cursor.id,
        },
      );

      // Supabase functions throw on non-2xx, but defensive coding is good practice
      if (response.status != 200) {
        throw Exception('Failed to load feed: ${response.data}');
      }

      // Safe JSON parsing
      final Map<String, dynamic> data =
          (response.data as Map<String, dynamic>?) ?? {};
      final List<dynamic> jsonPosts = (data['data'] as List<dynamic>?) ?? [];

      // Update pagination state for the NEXT call
      _cursor = _PageCursor(
        value: data['next_cursor'] as String?,
        id: data['next_cursor_id'] as String?,
      );
      _hasMore = data['has_more'] as bool? ?? false;

      // Parse and return the new posts
      return jsonPosts
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();

    } catch (e) {
      debugPrint('Error fetching feed: $e');
      rethrow; // Let the Provider handle the UI error state
    } finally {
      _isFetching = false;
    }
  }
}