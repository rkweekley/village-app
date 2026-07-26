import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/app.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/auth/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await SecureStorage.create();
  runApp(
    ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
      ],
      child: const AppBootstrap(),
    ),
  );
}

/// Wrapper that triggers auto-login check after the first frame.
/// Shows a loading splash while auth state is unknown.
class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).tryAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show splash while loading
    if (authState.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 80),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );
    }

    return const VillageApp();
  }
}
