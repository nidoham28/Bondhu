class FeedUtils {
  static String formatCount(int? count) {
    if (count == null || count <= 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  static String timeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 365) return '${(duration.inDays / 365).floor()}y';
    if (duration.inDays > 30) return '${(duration.inDays / 30).floor()}mo';
    if (duration.inDays > 0) return '${duration.inDays}d';
    if (duration.inHours > 0) return '${duration.inHours}h';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return 'Just now';
  }
}