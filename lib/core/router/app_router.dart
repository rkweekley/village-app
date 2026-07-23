import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/features/auth/pages/login_page.dart';
import 'package:village_app/features/family/pages/family_setup_page.dart';
import 'package:village_app/features/hub/pages/hub_page.dart';
import 'package:village_app/shared/widgets/placeholders.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/hub',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/family-setup',
        builder: (context, state) => const FamilySetupPage(),
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
            builder: (context, state) =>
                const PlaceholderPage(title: 'Chores', icon: Icons.checklist),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => const PlaceholderPage(
                    title: 'Chore Detail', icon: Icons.checklist),
              ),
            ],
          ),
          GoRoute(
            path: '/rewards',
            builder: (context, state) =>
                const PlaceholderPage(title: 'Rewards', icon: Icons.stars),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => const PlaceholderPage(
                    title: 'Reward Detail', icon: Icons.stars),
              ),
            ],
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) =>
                const PlaceholderPage(title: 'Calendar', icon: Icons.calendar_month),
          ),
          GoRoute(
            path: '/shopping',
            builder: (context, state) =>
                const PlaceholderPage(title: 'Shopping List', icon: Icons.shopping_cart),
          ),
        ],
      ),
    ],
  );
});
