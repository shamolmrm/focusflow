import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../shared/services/storage_service.dart';
import '../features/auth/login_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/permissions_screen.dart';
import '../features/onboarding/personalize_screen.dart';
import '../features/home/home_screen.dart';
import '../features/habits/habits_screen.dart';
import '../features/focus/focus_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/upgrade/upgrade_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state so router rebuilds on sign-in / sign-out
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final done = StorageService.onboardingDone;
      final skipped = StorageService.skipLogin;
      final isSignedIn = authAsync.valueOrNull != null;
      final loc = state.matchedLocation;

      final isOnboarding = loc == '/onboarding' ||
          loc == '/permissions' ||
          loc == '/personalize';
      final isLogin = loc == '/login';

      // Not onboarded yet → onboarding
      if (!done && !isOnboarding) return '/onboarding';

      // Onboarded but not logged in and hasn't skipped → login
      if (done && !isSignedIn && !skipped && !isLogin && !isOnboarding) {
        return '/login';
      }

      // Already logged in / skipped → skip login/onboarding screens
      if ((isSignedIn || skipped) && (isLogin || isOnboarding)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/permissions', builder: (_, _) => const PermissionsScreen()),
      GoRoute(path: '/personalize', builder: (_, _) => const PersonalizeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/home',
        pageBuilder: (_, state) => _fade(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/habits',
        pageBuilder: (_, state) => _fade(state, const HabitsScreen()),
      ),
      GoRoute(
        path: '/focus',
        pageBuilder: (_, state) => _fade(state, const FocusScreen()),
      ),
      GoRoute(
        path: '/analytics',
        pageBuilder: (_, state) => _fade(state, const AnalyticsScreen()),
      ),
      GoRoute(
        path: '/upgrade',
        pageBuilder: (_, state) => _slide(state, const UpgradeScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (_, state) => _slide(state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => _slide(state, const SettingsScreen()),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});

// Makes GoRouter react to auth state changes
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authStateProvider, (prev, next) => notifyListeners());
  }
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, anim, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
