import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/network/authenticated_client.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/billing/billing_service.dart';
import 'package:village_app/shared/utils/date_utils.dart';
import 'package:village_app/shared/utils/status_color.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  List<ProductDetails> _products = const [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool get _isStoreBilling => !kIsWeb;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    if (_isStoreBilling) {
      _loadProducts();
      _purchaseSub =
          ref.read(billingServiceProvider).purchaseStream.listen(_onPurchases);
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ref.read(billingServiceProvider).getStatus();
      if (mounted) setState(() { _status = res; _loading = false; });
    } on DioException catch (_) {
      if (mounted) setState(() { _error = 'Unable to load subscription info. Please check your connection.'; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ref.read(billingServiceProvider).fetchProducts();
      if (mounted) setState(() => _products = products);
    } catch (_) {
      // Products unavailable — plan cards fall back to a disabled state.
    }
  }

  Future<void> _purchase(String tier) async {
    if (_isStoreBilling) {
      await _buyViaStore(tier);
    } else {
      await _startStripeCheckout(tier);
    }
  }

  Future<void> _startStripeCheckout(String tier) async {
    setState(() => _actionLoading = true);
    try {
      final dio = ref.read(authenticatedDioProvider);
      final res = await dio.post('/api/stripe/create-checkout', data: {'tier': tier});
      final url = res.data['url'] as String;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on DioException catch (_) {
      _showSnack('Unable to load subscription info. Please check your connection.');
    } catch (e) {
      _showSnack('Failed to start checkout: $e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  ProductDetails? _findProduct(String tier) {
    final ids = BillingService.storeProductIds();
    final targetId = tier == 'annual' ? ids[1] : ids[0];
    for (final p in _products) {
      if (p.id == targetId) return p;
    }
    return null;
  }

  Future<void> _buyViaStore(String tier) async {
    final product = _findProduct(tier);
    if (product == null) {
      _showSnack('Subscription product unavailable. Please try again shortly.');
      return;
    }
    setState(() => _actionLoading = true);
    try {
      await ref.read(billingServiceProvider).buy(product);
      // The purchaseStream listener handles verification + completion.
    } catch (e) {
      _showSnack('Purchase failed: $e');
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(billingServiceProvider).restorePurchases();
    } catch (e) {
      _showSnack('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _verifyAndComplete(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        _showSnack(purchase.error?.message ?? 'Purchase failed.');
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    final raw = purchase.verificationData.serverVerificationData;
    final productId = purchase.productID;
    if (raw.isEmpty) {
      _showSnack('Could not verify purchase (no receipt).');
      return;
    }
    final billing = ref.read(billingServiceProvider);
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await billing.verifyApple(raw, productId);
      } else {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final token = map['purchaseToken'] as String?;
        if (token == null || token.isEmpty) {
          _showSnack('Could not verify purchase (missing token).');
          return;
        }
        await billing.verifyGoogle(token, productId);
      }
      await billing.completePurchase(purchase);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated!'),
            backgroundColor: VillageTheme.positive,
          ),
        );
        _loadStatus();
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map
          ? (data['error'] as String?) ?? 'Verification failed'
          : 'Verification failed';
      _showSnack(msg);
    } catch (e) {
      _showSnack('Verification failed: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openPortal() async {
    if (_isStoreBilling) {
      await _openStoreSubscriptions();
      return;
    }
    setState(() => _actionLoading = true);
    try {
      final dio = ref.read(authenticatedDioProvider);
      final res = await dio.post('/api/stripe/portal');
      final url = res.data['url'] as String;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on DioException catch (_) {
      _showSnack('Unable to load subscription info. Please check your connection.');
    } catch (e) {
      _showSnack('Failed to open portal: $e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _openStoreSubscriptions() async {
    final url = defaultTargetPlatform == TargetPlatform.iOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnack('Could not open subscription settings: $e');
    }
  }

  Future<void> _confirmCancel(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Your subscription will be canceled at the end of your current billing period. '
          'You will continue to have access until then. This action cannot be undone from the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
    if (confirm == true) await _cancelSubscription();
  }

  Future<void> _cancelSubscription() async {
    if (_isStoreBilling) {
      await _openStoreSubscriptions();
      return;
    }
    setState(() => _actionLoading = true);
    try {
      final dio = ref.read(authenticatedDioProvider);
      final res = await dio.post('/api/stripe/cancel');
      final endDate = res.data['endDate'] as String;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription will end ${formatDate(endDate)}.'),
            backgroundColor: VillageTheme.positive,
          ),
        );
        _loadStatus();
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map
          ? (data['error'] as String?) ?? 'Failed to cancel'
          : 'Failed to cancel. Please try again.';
      _showSnack(msg);
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageTheme.surfaceBase,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Subscription'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error loading subscription', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _loadStatus, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final status = _status!['status'] as String;
    final tier = _status!['tier'] as String?;
    final isInTrial = _status!['isInTrial'] as bool;
    final isExpiringSoon = _status!['isExpiringSoon'] as bool;

    // Role gate: children never see or trigger the paywall.
    if (!ref.read(authProvider).canManage) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 40, color: VillageTheme.textSecondary),
              SizedBox(height: 12),
              Text(
                'Only a parent or caregiver can manage the subscription.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VillageTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Status banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: statusColor(context, status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor(context, status).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(_statusIcon(status), size: 40, color: statusColor(context, status)),
              const SizedBox(height: 12),
              Text(
                _statusLabel(status, tier),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: statusColor(context, status),
                ),
              ),
              if (isInTrial) ...[
                const SizedBox(height: 4),
                Text(
                  'Trial ends ${formatDate(_status!['trialEndsAt'] as String)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
              if (!isInTrial && _status!['expiresAt'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Next billing: ${formatDate(_status!['expiresAt'] as String)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
              if (isExpiringSoon) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: VillageTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Trial ending soon — subscribe now!',
                      style: TextStyle(color: VillageTheme.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Plans
        if (status == 'trial' || status == 'expired' || status == 'canceled') ...[
          const Text('First month free',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Cancel anytime during your trial — you won\'t be charged.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 16),
          _PlanCard(
            title: 'Monthly',
            price: '\$5.99',
            period: '/month',
            features: const ['Full access', 'Up to 2 families', '12 members each'],
            highlighted: tier == 'monthly',
            isCurrent: tier == 'monthly' && !isInTrial,
            isLoading: _actionLoading,
            onTap: () => _purchase('monthly'),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            title: 'Annual',
            price: '\$49.99',
            period: '/year',
            features: const ['Everything in Monthly', 'Save 30% (\$4.17/mo)'],
            highlighted: tier == 'annual',
            isCurrent: tier == 'annual' && !isInTrial,
            isLoading: _actionLoading,
            onTap: () => _purchase('annual'),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment will be charged to your account when you subscribe. '
            'Subscriptions automatically renew unless auto-renew is turned off '
            'at least 24 hours before the end of the current period. You can '
            'manage and cancel anytime in your account settings. The free trial '
            'is for new subscribers only.',
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
          if (_isStoreBilling) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _actionLoading ? null : _restorePurchases,
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Restore Purchases'),
            ),
          ],
        ],

        if (status == 'active' || status == 'past_due') ...[
          if (status == 'past_due')
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: VillageTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: VillageTheme.danger),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Payment failed. Update your payment method to keep access.',
                        style: TextStyle(color: VillageTheme.danger, fontSize: 14)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _actionLoading ? null : _openPortal,
              style: FilledButton.styleFrom(
                backgroundColor: VillageTheme.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _actionLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Manage Subscription', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isStoreBilling
                ? 'Manage your subscription in your device\'s App Store or Google Play settings.'
                : 'Opens Stripe Customer Portal — update payment method, view invoices, or cancel.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
          // Cancel button — only for active subscriptions
          if (status == 'active') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _actionLoading
                    ? null
                    : (_isStoreBilling
                        ? _openStoreSubscriptions
                        : () => _confirmCancel(context)),
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: Text(
                    _isStoreBilling ? 'Manage in Store Settings' : 'Cancel Subscription'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isStoreBilling
                  ? 'Cancel your subscription from your device\'s subscription settings.'
                  : 'Your access continues until the end of your billing period.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ],
      ],
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'active': return Icons.check_circle_rounded;
      case 'trial': return Icons.timer_rounded;
      case 'past_due': return Icons.error_outline_rounded;
      case 'expired': return Icons.cancel_rounded;
      case 'canceled': return Icons.remove_circle_outline_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  String _statusLabel(String status, String? tier) {
    switch (status) {
      case 'active': return '${tier == 'annual' ? 'Annual' : 'Monthly'} Plan Active';
      case 'trial': return 'Free Trial';
      case 'past_due': return 'Payment Past Due';
      case 'expired': return 'Subscription Expired';
      case 'canceled': return 'Canceled';
      default: return status;
    }
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool highlighted;
  final bool isCurrent;
  final bool isLoading;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    this.highlighted = false,
    this.isCurrent = false,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlighted ? VillageTheme.primary : Colors.transparent,
          width: highlighted ? 2 : 0,
        ),
      ),
      color: VillageTheme.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                Text(price,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                        color: VillageTheme.primary)),
                Text(period,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_rounded, size: 16, color: VillageTheme.positive),
                      const SizedBox(width: 8),
                      Text(f, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Current Plan'),
                    )
                  : FilledButton(
                      onPressed: isLoading ? null : onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: highlighted ? VillageTheme.primary : VillageTheme.danger,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(highlighted ? 'Switch to $title' : 'Choose $title'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
