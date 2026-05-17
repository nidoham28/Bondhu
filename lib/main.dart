import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bondhu/app.dart';

/// Bondhu Application Entry Point
///
/// Architecture:
/// 1. Riverpod ProviderScope: Compile-safe state management
/// 2. Supabase.initialize: Single authenticated client for all features
/// 3. flutter_dotenv: Only public config (URL/Anon Key)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  runApp(const ProviderScope(child: BondhuApp()));
}