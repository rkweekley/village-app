import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:village_app/core/config.dart';
import 'package:village_app/core/network/authenticated_client.dart';

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

  /// Product identifiers for the current platform's store.
  static List<String> storeProductIds() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
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

  /// Whether this run is a native store build (iOS/Android), as opposed to web.
  static bool get useStoreBilling =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  /// Query the store for the subscription products (native only).
  Future<List<ProductDetails>> fetchProducts() async {
    final response = await _iap.queryProductDetails(storeProductIds().toSet());
    return response.productDetails;
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
