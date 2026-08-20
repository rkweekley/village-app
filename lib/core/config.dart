import 'package:flutter/foundation.dart' show kIsWeb;

/// Central configuration for the Village app.
///
/// On web the API lives behind the same nginx origin (baseUrl = ''),
/// but on native mobile there is no nginx proxy, so we point directly
/// at the public API endpoint.
class AppConfig {
  AppConfig._();

  /// v1.0 ships FREE: all subscription/payment UI is hidden and billing is not
  /// enforced. Flip to true once In-App Purchase lands (StoreKit 2 on iOS,
  /// Play Billing on Android) in v1.1. The Stripe checkout path in
  /// subscription_page.dart stays in place but is simply unreachable while
  /// this is false.
  static const bool subscriptionEnabled = false;

  /// Public API hostname — served by Nginx Proxy Manager on the Mac Mini
  /// via a Cloudflare-tunneled or port-forwarded public IP.
  static const _apiHost = 'api.villagefamily.app';

  /// Base URL for REST API calls (Dio).
  ///
  /// Web uses the empty-string convention so requests are relative to
  /// the page origin and nginx proxies `/api/` to the backend.
  /// Native mobile connects directly to the public API host.
  static String get apiBaseUrl {
    if (kIsWeb) return '';
    return 'https://$_apiHost';
  }

  /// Base URL for SignalR WebSocket connections.
  ///
  /// Same platform split as [apiBaseUrl].  The SignalR client replaces
  /// `https://` ↔ `wss://` and `http://` ↔ `ws://` automatically.
  static String get signalRBaseUrl {
    if (kIsWeb) return '';
    return 'https://$_apiHost';
  }

  /// Full HTTP base URL for health checks and local debugging
  /// (never used in production code — only for dev tooling).
  static String get httpBaseUrl {
    if (kIsWeb) return '';
    return 'http://$_apiHost';
  }
}
