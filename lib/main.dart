import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/app.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/auth/secure_storage.dart';
import 'package:village_app/core/signalr/signalr_provider.dart';

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

/// Triggers auto-login + SignalR after the first frame, then defers to
/// [VillageApp]. Keyed by auth status so the router widget subtree is
/// preserved across unknown → unauthenticated/authenticated transitions —
/// replacing the subtree would drop the deep link the router captured.
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
      ref.read(signalRConnectorProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider.select((s) => s.status));
    return KeyedSubtree(
      key: ValueKey(status),
      child: const VillageApp(),
    );
  }
}
