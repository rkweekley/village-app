import 'package:flutter/foundation.dart' show kIsWeb;

/// Central configuration for the Village app.
///
/// On web the API lives behind the same nginx origin (baseUrl = ''),
/// but on native mobile there is no nginx proxy, so we point directly
/// at the public API endpoint.
class AppConfig {
  AppConfig._();

  /// Subscriptions are required after the 30-day trial (no free tier).
  /// Web uses Stripe Checkout; native iOS/Android use StoreKit 2 / Play Billing
  /// with server-side receipt verification.
  static const bool subscriptionEnabled = true;

  /// StoreKit 2 product identifiers (iOS). Must match App Store Connect and the
  /// backend `Apple:MonthlyProductId` / `Apple:AnnualProductId` settings.
  static const String appleMonthlyProductId = 'village.monthly';
  static const String appleAnnualProductId = 'village.annual';

  /// Play Billing product identifiers (Android). Must match Play Console and the
  /// backend `Google:MonthlyProductId` / `Google:AnnualProductId` settings.
  static const String googleMonthlyProductId = 'village_monthly';
  static const String googleAnnualProductId = 'village_annual';

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
