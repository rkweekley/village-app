import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:village_app/core/auth/secure_storage.dart';
import 'package:village_app/core/signalr/signalr_service.dart';
import 'package:village_app/core/theme/theme_mode_provider.dart';
import 'package:village_app/main.dart';

// Screenshot harness for store listings.
//
// Logs in with real credentials, walks the key screens, and captures a
// screenshot of each via the integration_test binding + flutter drive.
//
// Run with:
//   flutter drive --driver=test_driver/screenshots.dart \
//     --target=integration_test/screenshots_test.dart -d <simulator-udid>

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('SCREENSHOT_EMAIL');
  const password = String.fromEnvironment('SCREENSHOT_PASSWORD');
  assert(email.isNotEmpty && password.isNotEmpty,
      'Pass --dart-define=SCREENSHOT_EMAIL=... --dart-define=SCREENSHOT_PASSWORD=...');

  testWidgets('capture store screenshots', (tester) async {
    final storage = await SecureStorage.create();
    final themeMode = await loadThemeMode();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          initialThemeModeProvider.overrideWithValue(themeMode),
          // SignalR can't reach the hub from the integration-test sandbox and
          // its async handshake error kills the test. Screenshots only need
          // auth + navigation, not live push — stub the service so the real
          // connector's connect/subscribe calls are no-ops.
          signalRServiceProvider.overrideWithValue(_NoopSignalRService(storage)),
        ],
        child: const AppBootstrap(),
      ),
    );

    final binding = IntegrationTestWidgetsFlutterBinding.instance;

    // Wait up to ~20s for the login screen's text fields to appear.
    await _waitFor(tester, find.byType(TextFormField), timeout: const Duration(seconds: 20));
    await _pump(tester, const Duration(seconds: 2));

    // 01 - Login screen.
    await binding.takeScreenshot('01_login');

    // Fill the two text fields in order (email, then password).
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), email);
    await _pump(tester, const Duration(milliseconds: 300));
    await tester.enterText(fields.at(1), password);
    await _pump(tester, const Duration(milliseconds: 300));

    // Tap Sign in.
    final signIn = find.widgetWithText(FilledButton, 'Sign in');
    await _waitFor(tester, signIn, timeout: const Duration(seconds: 5));
    await tester.tap(signIn.first);
    await _pump(tester, const Duration(milliseconds: 500));

    // Wait for login + redirect to the Hub shell (bottom nav appears).
    await _waitFor(tester, find.byType(NavigationBar), timeout: const Duration(seconds: 30));
    await _pump(tester, const Duration(seconds: 4));

    // Capture the Hub screen.
    await binding.takeScreenshot('02_hub');

    // Chores (quick action on Hub).
    await _tapText(tester, 'Chores');
    await _settleAndShot(tester, binding, '03_chores');

    // Back to Hub, then Rewards.
    await _goBackToHub(tester);
    await _tapText(tester, 'Rewards');
    await _settleAndShot(tester, binding, '04_rewards');

    // Back to Hub, then Tasks tab.
    await _goBackToHub(tester);
    await _tapNavTab(tester, 'Tasks');
    await _settleAndShot(tester, binding, '05_tasks');

    // Meals quick action.
    await _tapNavTab(tester, 'Hub');
    await _pump(tester, const Duration(seconds: 1));
    await _tapText(tester, 'Meals');
    await _settleAndShot(tester, binding, '06_meals');

    // Family tab.
    await _goBackToHub(tester);
    await _tapNavTab(tester, 'Family');
    await _settleAndShot(tester, binding, '07_family');

    // Calendar tab.
    await _tapNavTab(tester, 'Calendar');
    await _settleAndShot(tester, binding, '08_calendar');

    // Shopping tab.
    await _tapNavTab(tester, 'Shopping');
    await _settleAndShot(tester, binding, '09_shopping');

    // Finish.
    await _pump(tester, const Duration(seconds: 1));
  });
}

/// Pumps the frame once (keeps timers moving) without requiring all to settle —
/// avoids hanging on infinite loading spinners.
Future<void> _pump(WidgetTester tester, Duration wait) async {
  await tester.pump(wait);
  await Future<void>.delayed(wait);
  await tester.pump(Duration.zero);
}

/// Polls until [finder] matches (or times out). Uses pumpAndSettle (wrapped in
/// try/catch so infinite loading spinners don't throw) to let async redirects
/// and network round-trips complete.
Future<void> _waitFor(WidgetTester tester, Finder finder,
    {required Duration timeout}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
    } catch (_) {
      // Infinite spinner — stop trying to settle, just pump a frame.
      await tester.pump(Duration.zero);
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw StateError('Timed out waiting for ${finder.description}');
}

/// Taps the first widget matching [text] if present.
Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  if (f.evaluate().isNotEmpty) {
    await tester.tap(f.first);
    await _pump(tester, const Duration(milliseconds: 500));
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.pump(Duration.zero);
  }
}

/// Taps a bottom navigation destination by its label.
Future<void> _tapNavTab(WidgetTester tester, String label) async {
  final f = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  if (f.evaluate().isNotEmpty) {
    await tester.tap(f.first);
    await _pump(tester, const Duration(milliseconds: 500));
  }
}

/// Naps back to the Hub tab via the bottom nav (secondary pages have one).
Future<void> _goBackToHub(WidgetTester tester) async {
  // Try the app-bar back button first (the app uses arrow_back_rounded with
  // NO tooltip, so match the icon), then the Hub tab.
  final back = find.byIcon(Icons.arrow_back_rounded);
  if (back.evaluate().isNotEmpty) {
    await tester.tap(back.first);
    await _pump(tester, const Duration(seconds: 1));
  }
  await _tapNavTab(tester, 'Hub');
  await _pump(tester, const Duration(seconds: 1));
}

/// Lets the screen settle then captures it.
Future<void> _settleAndShot(
    WidgetTester tester,
    IntegrationTestWidgetsFlutterBinding binding,
    String name) async {
  await Future<void>.delayed(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
  await binding.takeScreenshot(name);
}

/// A no-op stand-in for [SignalRService] so the screenshot run never opens a
/// real WebSocket. Message streams stay open-but-silent and connect/disconnect
/// are no-ops.
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
  void dispose() {
    _controller.close();
  }
}