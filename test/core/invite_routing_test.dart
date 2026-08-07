import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/core/router/app_router.dart';

void main() {
  group('invite deep link regression', () {
    test('/register/:code is a registered auth route', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      final paths = router.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();
      expect(paths, contains('/register/:code'));
      expect(paths, contains('/register'));
    });

    test('/splash route exists for unknown auth state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      final paths = router.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();
      expect(paths, contains('/splash'));
    });
  });
}
