import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:village_app/core/config.dart';
import 'package:village_app/core/network/authenticated_client.dart';

/// Result of a store product query.
///
/// `in_app_purchase` returns THREE things from `queryProductDetails`:
/// the products it resolved, the identifiers it could not resolve
/// (`notFoundIDs`), and an optional transport-level [error]. The previous
/// implementation returned only `productDetails` and dropped the other two, so
/// a total StoreKit failure looked identical to "no product configured" and
/// was invisible in logs and telemetry (App Review 2.1(b), 2026-10-01).
///
/// This type keeps every part of the response so the failure can be diagnosed
/// from the field.
class ProductFetchResult {
  const ProductFetchResult({
    required this.requestedIds,
    this.products = const <ProductDetails>[],
    this.notFoundIds = const <String>[],
    this.errorCode,
    this.errorMessage,
    this.storefront,
  });

  /// The product identifiers that were asked for.
  final List<String> requestedIds;

  /// Products StoreKit / Play Billing actually returned.
  final List<ProductDetails> products;

  /// Identifiers the store did not recognise. Non-empty means the store has no
  /// record of that product for this app bundle in this storefront.
  final List<String> notFoundIds;

  /// `IAPError.code` from the plugin (e.g. `storekit_no_response`).
  final String? errorCode;

  /// `IAPError.message` from the plugin.
  final String? errorMessage;

  /// Storefront country code (ISO-3166-1 alpha-2 on Android, alpha-3 on iOS)
  /// of the device at query time. Products are only returned when they are
  /// available in this storefront.
  final String? storefront;

  /// True when the store returned nothing usable.
  bool get isEmpty => products.isEmpty;

  /// True when at least one requested product resolved.
  bool get hasAnyProduct => products.isNotEmpty;

  /// A single line an operator (or a screenshot in App Review) can carry:
  /// what was asked for, what came back, what the store said.
  String diagnosticsSummary() {
    final buffer = StringBuffer()
      ..write('Asked for: ${requestedIds.join(', ')}')
      ..write(' | returned: ${products.isEmpty ? 'none' : products.map((p) => p.id).join(', ')}');
    if (notFoundIds.isNotEmpty) {
      buffer.write(' | notFoundIDs: ${notFoundIds.join(', ')}');
    }
    if (errorCode != null || errorMessage != null) {
      buffer.write(' | store error: ${errorCode ?? 'unknown'}');
      if (errorMessage != null && errorMessage!.isNotEmpty) {
        buffer.write(' (${errorMessage!})');
      }
    }
    if (storefront != null && storefront!.isNotEmpty) {
      buffer.write(' | storefront: ${storefront!}');
    }
    return buffer.toString();
  }
}

/// Billing service: server-side verification of Apple / Google purchases plus
/// the thin `in_app_purchase` wrapper used by the native paywall.
///
/// Web (Stripe) checkout is handled directly in subscription_page.dart; this
/// service covers the native StoreKit 2 / Play Billing paths and the unified
/// `/api/billing/status` endpoint.
class BillingService {
  final Dio _dio;
  final InAppPurchase _iap;

  BillingService(this._dio, [InAppPurchase? iap])
      : _iap = iap ?? InAppPurchase.instance;

  /// Current subscription status for the family (any provider).
  Future<Map<String, dynamic>> getStatus() async {
    final res = await _dio.get('/api/billing/status');
    return res.data as Map<String, dynamic>;
  }

  /// Verify an Apple StoreKit 2 transaction JWS with the server.
  Future<Map<String, dynamic>> verifyApple(
      String transactionJws, String productId) async {
    final res = await _dio.post('/api/billing/apple/verify', data: {
      'transactionJws': transactionJws,
      'productId': productId,
    });
    return res.data as Map<String, dynamic>;
  }

  /// Verify a Google Play purchase token with the server.
  Future<Map<String, dynamic>> verifyGoogle(
      String purchaseToken, String productId) async {
    final res = await _dio.post('/api/billing/google/verify', data: {
      'purchaseToken': purchaseToken,
      'productId': productId,
    });
    return res.data as Map<String, dynamic>;
  }

  /// Product identifiers for a given platform's store.
  static List<String> storeProductIdsFor(TargetPlatform platform) {
    if (platform == TargetPlatform.iOS) {
      return const [
        AppConfig.appleMonthlyProductId,
        AppConfig.appleAnnualProductId,
      ];
    }
    return const [
      AppConfig.googleMonthlyProductId,
      AppConfig.googleAnnualProductId,
    ];
  }

  /// Product identifiers for the current platform's store.
  static List<String> storeProductIds() =>
      storeProductIdsFor(defaultTargetPlatform);

  /// The store product for [tier] (`monthly` / `annual`), or null when the
  /// store did not return it.
  ///
  /// **A null result means NOT PURCHASABLE.** Callers must disable the purchase
  /// affordance rather than fall back to a hardcoded price — presenting a
  /// product the store has not returned is exactly the App Review 2.1(b) defect
  /// on build 6.
  static ProductDetails? productForTier(
    List<ProductDetails> products,
    String tier, {
    List<String>? ids,
  }) {
    final list = ids ?? storeProductIds();
    if (list.length < 2) return null;
    final targetId = tier == 'annual' ? list[1] : list[0];
    for (final product in products) {
      if (product.id == targetId) return product;
    }
    return null;
  }

  /// The store's own localized price string, or an em dash when the product did
  /// not resolve. Never returns a hardcoded price.
  static String planPriceLabel(ProductDetails? product) =>
      (product != null && product.price.isNotEmpty) ? product.price : '—';

  /// Whether this run is a native store build (iOS/Android), as opposed to web.
  static bool get useStoreBilling =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  /// Storefront country code, or null when the platform cannot report it.
  ///
  /// Never throws: telemetry must not be able to break the paywall.
  Future<String?> storefrontCountryCode() async {
    if (kIsWeb) return null;
    try {
      final code = await _iap.countryCode();
      return code.isEmpty ? null : code;
    } catch (e) {
      debugPrint('[StoreKit] storefront lookup failed: $e');
      return null;
    }
  }

  /// Whether the store is reachable / payments are possible on this device.
  Future<bool> isStoreAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _iap.isAvailable();
    } catch (e) {
      debugPrint('[StoreKit] isAvailable() failed: $e');
      return false;
    }
  }

  /// Query the store for the subscription products (native only).
  ///
  /// Never throws — a store failure is returned as a [ProductFetchResult]
  /// carrying the error, the unresolved identifiers and the storefront, and is
  /// logged so the next failure is diagnosable from the field. Callers must
  /// treat an empty [ProductFetchResult.products] as "not purchasable" and must
  /// not offer the product for purchase.
  Future<ProductFetchResult> fetchProducts() async {
    final ids = storeProductIds();
    try {
      final response = await _iap.queryProductDetails(ids.toSet());
      final result = ProductFetchResult(
        requestedIds: ids,
        products: response.productDetails,
        notFoundIds: response.notFoundIDs,
        errorCode: response.error?.code,
        errorMessage: response.error?.message,
        storefront: await storefrontCountryCode(),
      );
      if (result.isEmpty) {
        debugPrint('[StoreKit] queryProductDetails FAILED — ${result.diagnosticsSummary()}');
      } else {
        debugPrint('[StoreKit] queryProductDetails ok — ${result.diagnosticsSummary()}');
      }
      return result;
    } catch (e, stack) {
      debugPrint('[StoreKit] queryProductDetails threw: $e\n$stack');
      return ProductFetchResult(
        requestedIds: ids,
        notFoundIds: ids,
        errorCode: 'exception',
        errorMessage: e.toString(),
        storefront: await storefrontCountryCode(),
      );
    }
  }

  /// Query the store, retrying a bounded number of times while nothing resolves.
  ///
  /// StoreKit can return an empty product list on a cold launch before the
  /// store front has resolved, so a single empty response is not conclusive.
  /// Each attempt is logged. Returns the first non-empty result, else the last.
  Future<ProductFetchResult> fetchProductsWithRetry({
    int attempts = 3,
    Duration delay = const Duration(milliseconds: 900),
  }) async {
    var last = await fetchProducts();
    for (var attempt = 2; attempt <= attempts && last.isEmpty; attempt++) {
      debugPrint('[StoreKit] retry $attempt/$attempts after empty product list');
      await Future<void>.delayed(delay);
      last = await fetchProducts();
    }
    return last;
  }

  /// Start the store purchase flow for a subscription product.
  Future<void> buy(ProductDetails product) async {
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  /// Acknowledge a purchase with the store after successful server verification.
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  /// Restore prior purchases (native only).
  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Stream of purchase updates from the store.
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;
}

final billingServiceProvider = Provider<BillingService>((ref) {
  final dio = ref.read(authenticatedDioProvider);
  return BillingService(dio);
});
