import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:village_app/features/billing/billing_service.dart';

/// Regression tests for the App Review 2.1(b) defect (build 6, 2026-10-01).
///
/// Two things went wrong on build 6 and both are pinned here:
///   1. `fetchProducts()` dropped `ProductDetailsResponse.error` and
///      `.notFoundIDs`, so a StoreKit failure was invisible.
///   2. The paywall rendered hardcoded prices with a live `onTap` even when the
///      store had returned no product, so Apple's reviewer got a tappable
///      button plus "subscription product unavailable".
ProductDetails _product({
  required String id,
  String price = r'$5.99',
}) =>
    ProductDetails(
      id: id,
      title: id,
      description: 'test product',
      price: price,
      rawPrice: 5.99,
      currencyCode: 'USD',
      currencySymbol: r'$',
    );

void main() {
  const iosIds = ['village.monthly', 'village.annual'];
  const androidIds = ['village_monthly', 'village_annual'];

  group('store product identifiers match the stores exactly', () {
    test('iOS uses the dotted App Store Connect identifiers', () {
      expect(BillingService.storeProductIdsFor(TargetPlatform.iOS), iosIds);
    });

    test('Android uses the underscored Play Console identifiers', () {
      expect(BillingService.storeProductIdsFor(TargetPlatform.android),
          androidIds);
    });
  });

  group('productForTier is the purchasable gate', () {
    test('resolves the monthly product', () {
      final products = [_product(id: 'village.monthly'), _product(id: 'village.annual')];
      final found = BillingService.productForTier(products, 'monthly', ids: iosIds);
      expect(found, isNotNull);
      expect(found!.id, 'village.monthly');
    });

    test('resolves the annual product', () {
      final products = [_product(id: 'village.annual')];
      final found = BillingService.productForTier(products, 'annual', ids: iosIds);
      expect(found, isNotNull);
      expect(found!.id, 'village.annual');
    });

    test('returns null when the store returned nothing — NOT purchasable', () {
      expect(BillingService.productForTier(const [], 'monthly', ids: iosIds),
          isNull);
      expect(BillingService.productForTier(const [], 'annual', ids: iosIds),
          isNull);
    });

    test('returns null when only the other tier resolved', () {
      final products = [_product(id: 'village.monthly')];
      expect(BillingService.productForTier(products, 'annual', ids: iosIds),
          isNull);
    });

    test('ignores a product whose id is not one of ours', () {
      final products = [_product(id: 'com.someone.else.monthly')];
      expect(BillingService.productForTier(products, 'monthly', ids: iosIds),
          isNull);
    });
  });

  group('planPriceLabel never shows a hardcoded price', () {
    test('prefers the store price', () {
      expect(
        BillingService.planPriceLabel(_product(id: 'village.monthly', price: r'$5.99')),
        r'$5.99',
      );
    });

    test('falls back to an em dash when the product did not resolve', () {
      expect(BillingService.planPriceLabel(null), '—');
    });

    test('falls back to an em dash when the store price is empty', () {
      expect(
        BillingService.planPriceLabel(_product(id: 'village.monthly', price: '')),
        '—',
      );
    });
  });

  group('ProductFetchResult keeps the StoreKit diagnosis', () {
    test('a total StoreKit failure is diagnosable', () {
      const result = ProductFetchResult(
        requestedIds: iosIds,
        notFoundIds: iosIds,
        errorCode: 'storekit_no_response',
        errorMessage: 'StoreKit: Failed to get response from platform.',
        storefront: 'USA',
      );

      expect(result.isEmpty, isTrue);
      expect(result.hasAnyProduct, isFalse);

      final summary = result.diagnosticsSummary();
      expect(summary, contains('village.monthly'));
      expect(summary, contains('village.annual'));
      expect(summary, contains('notFoundIDs'));
      expect(summary, contains('storekit_no_response'));
      expect(summary, contains('storefront: USA'));
      expect(summary, contains('returned: none'));
    });

    test('a successful fetch reports the resolved products', () {
      final result = ProductFetchResult(
        requestedIds: iosIds,
        products: [_product(id: 'village.monthly')],
        notFoundIds: const ['village.annual'],
        storefront: 'IRL',
      );

      expect(result.hasAnyProduct, isTrue);
      expect(result.isEmpty, isFalse);

      final summary = result.diagnosticsSummary();
      expect(summary, contains('returned: village.monthly'));
      expect(summary, contains('notFoundIDs: village.annual'));
      expect(summary, contains('storefront: IRL'));
    });

    test('omits absent fields rather than printing nulls', () {
      const result = ProductFetchResult(
        requestedIds: iosIds,
        products: [],
      );
      final summary = result.diagnosticsSummary();
      expect(summary, isNot(contains('null')));
      expect(summary, isNot(contains('store error')));
    });
  });
}
