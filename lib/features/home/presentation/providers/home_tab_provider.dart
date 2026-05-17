import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks active bottom navigation tab.
/// Using `StateProvider` allows UI to reactively update without rebuilding unnecessary widgets.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);