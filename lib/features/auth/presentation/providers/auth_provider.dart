import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bondhu/services/supabase_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.authState;
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseService.currentUser;
});