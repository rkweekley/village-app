import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/features/auth/pages/login_page.dart';
import 'package:village_app/features/auth/pages/register_page.dart';
import 'package:village_app/features/auth/pages/forgot_password_page.dart';
import 'package:village_app/features/family/pages/family_page.dart';
import 'package:village_app/features/family/pages/family_setup_page.dart';
import 'package:village_app/features/family/pages/subscription_page.dart';
import 'package:village_app/features/hub/pages/hub_page.dart';
import 'package:village_app/features/tasks/pages/tasks_page.dart';
import 'package:village_app/features/rewards/pages/rewards_page.dart';
import 'package:village_app/features/calendar/pages/calendar_page.dart';
import 'package:village_app/features/shopping/pages/shopping_lists_page.dart';
import 'package:village_app/features/meals/pages/meals_page.dart';
import 'package:village_app/features/chores/pages/chores_page.dart';
import 'package:village_app/features/school/pages/school_page.dart';
import 'package:village_app/features/notifications/pages/notifications_page.dart';
import 'package:village_app/features/profile/pages/edit_profile_page.dart';
import 'package:village_app/shared/widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Build the router, re-evaluating redirects whenever auth state changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' ||
          location.startsWith('/register') ||
          location.startsWith('/forgot-password') || location.startsWith('/reset-password');
      final isUnknown = authState.isLoading;

      // Still checking token — stay put
      if (isUnknown) return null;

      // Not authenticated → login
      if (!isAuthenticated && !isAuthRoute) return '/login';

      // Authenticated
      if (isAuthenticated) {
        if (isAuthRoute) return '/hub';
        if (location == '/family-setup') return null;
      }

      return null;
    },
    routes: [
      // ── Public pages (no shell) ──
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register/:code',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RegisterPage(
          inviteCode: state.pathParameters['code'],
        ),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password/:token',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ResetPasswordPage(
          token: state.pathParameters['token'],
          email: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/family-setup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FamilySetupPage(),
      ),

      // ── Shell routes (5 main tabs) ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/hub',
                builder: (context, state) => const HubPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/family',
                builder: (context, state) => const FamilyPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shopping',
                builder: (context, state) => const ShoppingListsPage(),
              ),
            ],
          ),
        ],
      ),

      // ── Secondary pages (pushed full-screen from shell or overflow) ──
      GoRoute(
        path: '/chores',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChoresPage(),
      ),
      GoRoute(
        path: '/school',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SchoolPage(),
      ),
      GoRoute(
        path: '/rewards',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RewardsPage(),
      ),
      GoRoute(
        path: '/meals',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MealsPage(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/subscription',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubscriptionPage(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfilePage(),
      ),
      // ── Shopping detail (pushed from shell tab) ──
      GoRoute(
        path: '/shopping-detail/:listId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ShoppingListDetailPage(
          listId: state.pathParameters['listId']!,
        ),
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
