import 'package:bondhu/features/auth/presentation/providers/auth_provider.dart';
import 'package:bondhu/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bondhu/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bondhu/features/auth/presentation/screens/login_screen.dart';
import 'package:bondhu/features/auth/presentation/screens/splash_screen.dart';
import 'package:bondhu/features/home/presentation/screens/home_screen.dart';

// Routes that do NOT require authentication.
const _publicRoutes = {'/login', '/register', '/forgot-password'};

final goRouterProvider = Provider<GoRouter>((ref) {
  // Rebuild the router whenever auth state changes so redirects re-evaluate.
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      // While the auth stream is still loading, stay on splash.
      if (authState.isLoading) return '/';

      final isLoggedIn = authState.valueOrNull?.session != null;
      final isOnPublicRoute = _publicRoutes.contains(state.matchedLocation);
      final isOnSplash = state.matchedLocation == '/';

      // Not logged in and trying to access a protected route → login.
      if (!isLoggedIn && !isOnPublicRoute && !isOnSplash) return '/login';

      // Logged in but landing on a public/splash route → home.
      if (isLoggedIn && (isOnPublicRoute || isOnSplash)) return '/home';

      // No redirect needed.
      return null;
    },
  );
});