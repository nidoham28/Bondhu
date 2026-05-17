import 'dart:developer' as developer;

/// Production-Safe Logger
///
/// avoid_print lint enforced — use this for all logging.
class AppLogger {
  AppLogger._();

  static void info(String message, {String tag = 'Bondhu'}) {
    developer.log('ℹ️ $message', name: tag, level: 800);
  }

  static void error(
      String message, {
        String tag = 'Bondhu',
        Object? error,
        StackTrace? stackTrace,
      }) {
    developer.log(
      '❌ $message',
      name: tag,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  static void debug(String message, {String tag = 'Bondhu'}) {
    developer.log('🐛 $message', name: tag, level: 700);
  }
}