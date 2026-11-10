import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/core/router/app_router.dart';

/// Flatten the route tree, joining child paths onto their parent so relative
/// child segments (' :token ') are checked as full locations.
List<String> _allPaths(List<RouteBase> routes, [String parent = '']) {
  final paths = <String>[];
  for (final route in routes) {
    if (route is GoRoute) {
      final full = route.path.startsWith('/')
          ? route.path
          : '$parent/${route.path}';
      paths.add(full);
      if (route.routes.isNotEmpty) {
        paths.addAll(_allPaths(route.routes, full));
      }
    } else if (route is ShellRoute) {
      paths.addAll(_allPaths(route.routes, parent));
    } else if (route is StatefulShellRoute) {
      for (final branch in route.branches) {
        paths.addAll(_allPaths(branch.routes, parent));
      }
    }
  }
  return paths;
}

void main() {
  group('password reset deep link', () {
    test('query-token and path-token reset locations are both registered', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      final paths = _allPaths(router.configuration.routes);
      // Emailed link: /#/reset-password?token=<hex>&email=<addr>
      expect(paths, contains('/reset-password'));
      // Older/alternate link form: /#/reset-password/<token>
      expect(paths, contains('/reset-password/:token'));
    });

    testWidgets('emailed reset link renders the form, no GoException',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      // Exactly what the reset email points at (GoRouter strips the '#').
      router.go(
        '/reset-password'
        '?token=279B082C2E94FE74A7879C8A9FA717198BB225C616236403312F9C4C7EEAF363'
        '&email=rweekley%40gmail.com',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Set a new password'), findsOneWidget);
      // Token and email from the URL are prefilled so the user only picks a password.
      expect(
        find.text(
          '279B082C2E94FE74A7879C8A9FA717198BB225C616236403312F9C4C7EEAF363',
        ),
        findsOneWidget,
      );
      expect(find.text('rweekley@gmail.com'), findsOneWidget);
    });
  });
}
