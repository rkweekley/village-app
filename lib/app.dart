import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/router/app_router.dart';
import 'package:village_app/core/theme/village_theme.dart';

class VillageApp extends ConsumerWidget {
  const VillageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Village',
      debugShowCheckedModeBanner: false,
      theme: VillageTheme.light,
      darkTheme: VillageTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
