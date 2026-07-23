import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/features/auth/pages/login_page.dart';
import 'package:village_app/features/auth/pages/register_page.dart';
import 'package:village_app/features/family/pages/family_page.dart';
import 'package:village_app/features/family/pages/family_setup_page.dart';
import 'package:village_app/features/hub/pages/hub_page.dart';
import 'package:village_app/features/chores/pages/chores_page.dart';
import 'package:village_app/features/rewards/pages/rewards_page.dart';
import 'package:village_app/features/calendar/pages/calendar_page.dart';
import 'package:village_app/features/shopping/pages/shopping_lists_page.dart';
import 'package:village_app/shared/widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Build the router, re-evaluating redirects whenever auth state changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';
      final isUnknown = authState.isLoading;

      // Still checking token — stay put
      if (isUnknown) return null;

      // Not authenticated → login
      if (!isAuthenticated && !isAuthRoute) return '/login';

      // Authenticated
      if (isAuthenticated) {
        // On auth route → determine destination
        if (isAuthRoute) {
          if (authState.authResponse?.isNewFamily == true) {
            return '/family-setup';
          }
          return '/hub';
        }

        // Already on family-setup page — let it stay
        if (location == '/family-setup') return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/family-setup',
        builder: (context, state) => const FamilySetupPage(),
      ),
      GoRoute(
        path: '/family',
        builder: (context, state) => const FamilyPage(),
      ),
      // ── App Shell (bottom nav) ──
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/hub',
            builder: (context, state) => const HubPage(),
          ),
          GoRoute(
            path: '/chores',
            builder: (context, state) => const ChoresPage(),
          ),
          GoRoute(
            path: '/rewards',
            builder: (context, state) => const RewardsPage(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: '/shopping',
            builder: (context, state) => const ShoppingListsPage(),
          ),
        ],
      ),
    ],
  );

  // Re-run the redirect guard whenever auth state changes
  ref.listen(authProvider, (prev, next) {
    if (prev?.status != next.status) {
      router.refresh();
    }
  });

  return router;
});
