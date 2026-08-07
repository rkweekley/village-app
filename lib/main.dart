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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authProvider.notifier).tryAutoLogin();
      ref.read(signalRConnectorProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider.select((s) => s.status));
    // Only key the subtree during the initial unknown phase to preserve
    // the router across storage-read; after that let it live across
    // all auth transitions to avoid needless full-tree rebuilds.
    if (status == AuthStatus.unknown) {
      return KeyedSubtree(
        key: const ValueKey('bootstrap'),
        child: const VillageApp(),
      );
    }
    return const VillageApp();
  }
}
