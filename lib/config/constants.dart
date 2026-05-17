/// Centralized Application Constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Bondhu';
  static const String appVersion = '1.0.0';

  static const int defaultPageSize = 20;
  static const int maxPostLength = 2200;
  static const int storyDurationSeconds = 15;

  static const String cacheKeyPrefix = 'bondhu_cache';
  static const Duration cacheExpiry = Duration(hours: 24);

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double borderRadius = 12.0;
  static const double avatarRadiusSmall = 20.0;
  static const double avatarRadiusMedium = 32.0;
  static const double avatarRadiusLarge = 48.0;
}