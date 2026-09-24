import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:village_app/core/auth/secure_storage.dart';
import 'package:village_app/core/signalr/signalr_service.dart';
import 'package:village_app/core/theme/theme_mode_provider.dart';
import 'package:village_app/main.dart';

// Dedicated paywall capture for App Review subscription screenshots.
//
// Logs in as a TRIAL account (so the $5.99 / $49.99 plan cards render) and
// deep-links to /subscription, then captures the paywall for the reviewer.
//
// Run:
//   flutter drive --driver=test_driver/screenshots.dart \
//     --target=integration_test/subscription_screenshot_test.dart \
//     -d <simulator-udid> \
//     --dart-define=SCREENSHOT_EMAIL=... --dart-define=SCREENSHOT_PASSWORD=...
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('SCREENSHOT_EMAIL');
  const password = String.fromEnvironment('SCREENSHOT_PASSWORD');
  assert(email.isNotEmpty && password.isNotEmpty, 'Missing SCREENSHOT_EMAIL/PASSWORD');

  testWidgets('capture subscription paywall screenshot', (tester) async {
    final storage = await SecureStorage.create();
    final themeMode = await loadThemeMode();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          initialThemeModeProvider.overrideWithValue(themeMode),
          signalRServiceProvider.overrideWithValue(_NoopSignalRService(storage)),
        ],
        child: const AppBootstrap(),
      ),
    );

    final binding = IntegrationTestWidgetsFlutterBinding.instance;

    await _waitFor(tester, find.byType(TextFormField), timeout: const Duration(seconds: 20));
    await _pump(tester, const Duration(seconds: 2));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), email);
    await _pump(tester, const Duration(milliseconds: 300));
    await tester.enterText(fields.at(1), password);
    await _pump(tester, const Duration(milliseconds: 300));

    final signIn = find.widgetWithText(FilledButton, 'Sign in');
    await _waitFor(tester, signIn, timeout: const Duration(seconds: 5));
    debugPrint('[HARNESS] tapping Sign in');
    await tester.tap(signIn.first);
    await _pump(tester, const Duration(milliseconds: 500));

    // A trial account is auto-redirected to the paywall (/subscription) right
    // after login — there is NO NavigationBar shell on this screen. Wait for
    // the SubscriptionPage content (plan cards) instead.
    debugPrint('[HARNESS] waiting for paywall plan cards');
    await _waitFor(tester, find.textContaining('Monthly'), timeout: const Duration(seconds: 30));
    await _waitFor(tester, find.textContaining('Annual'), timeout: const Duration(seconds: 15));
    await _waitFor(tester, find.textContaining('\$5.99'), timeout: const Duration(seconds: 15));
    await Future<void>.delayed(const Duration(seconds: 3));
    await _pump(tester, const Duration(seconds: 1));

    await binding.takeScreenshot('10_subscription');

    await _pump(tester, const Duration(seconds: 1));
  });
}

Future<void> _pump(WidgetTester tester, Duration wait) async {
  await tester.pump(wait);
  await Future<void>.delayed(wait);
  await tester.pump(Duration.zero);
}

Future<void> _waitFor(WidgetTester tester, Finder finder,
    {required Duration timeout}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
    } catch (_) {
      await tester.pump(Duration.zero);
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw StateError('Timed out waiting for ${finder.description}');
}

/// Like [_waitFor] but returns true/false instead of throwing.
class _NoopSignalRService extends SignalRService {
  _NoopSignalRService(SecureStorage storage)
      : super(baseUrl: 'https://stub', storage: storage);

  final _controller = StreamController<SignalRMessage>.broadcast();
  @override
  Stream<SignalRMessage> get familyMessages => _controller.stream;
  @override
  Stream<SignalRMessage> get choresMessages => _controller.stream;
  @override
  Stream<SignalRMessage> get pointsMessages => _controller.stream;
  @override
  Stream<SignalRMessage> get notificationsMessages => _controller.stream;
  @override
  Stream<SignalRMessage> get shoppingMessages => _controller.stream;
  @override
  Future<void> connectAll(String familyId, String userId) async {}
  @override
  Future<void> disconnectAll() async {}
  @override
  bool get isConnected => true;
  @override
  void dispose() { _controller.close(); }
}