class FeedUtils {
  static String formatCount(int? count) {
    if (count == null || count <= 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1_000_000) {
      final k = count / 1000;
      // Show "1K" not "1.0K"
      return k == k.truncateToDouble() ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    final m = count / 1_000_000;
    return m == m.truncateToDouble() ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
  }

  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }
}