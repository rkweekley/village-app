import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:village_app/core/network/authenticated_client.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/family/family_service.dart';
import 'package:dio/dio.dart';

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

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(authenticatedDioProvider);
      final res = await dio.get('/api/stripe/status');
      if (mounted) setState(() { _status = res.data as Map<String, dynamic>; _loading = false; });
    } on DioException catch (_) {
      if (mounted) setState(() { _error = 'Unable to load subscription info. Please check your connection.'; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _startCheckout(String tier) async {
    setState(() => _actionLoading = true);
    try {
      final dio = ref.read(authenticatedDioProvider);
      final res = await dio.post('/api/stripe/create-checkout', data: {'tier': tier});
      final url = res.data['url'] as String;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load subscription info. Please check your connection.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start checkout: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _openPortal() async {
    setState(() => _actionLoading = true);
    try {
      final dio = ref.read(authenticatedDioProvider);
      final res = await dio.post('/api/stripe/portal');
      final url = res.data['url'] as String;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load subscription info. Please check your connection.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open portal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
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
    setState(() => _actionLoading = true);
    try {
      final dio = ref.read(authenticatedDioProvider);
      final res = await dio.post('/api/stripe/cancel');
      final endDate = res.data['endDate'] as String;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription will end ${_formatDate(endDate)}.'),
            backgroundColor: VillageTheme.positive,
          ),
        );
        _loadStatus();
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data is Map
            ? e.response!.data['error'] as String? ?? 'Failed to cancel'
            : 'Failed to cancel. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Status banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _statusColor(status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(_statusIcon(status), size: 40, color: _statusColor(status)),
              const SizedBox(height: 12),
              Text(
                _statusLabel(status, tier),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(status),
                ),
              ),
              if (isInTrial) ...[
                const SizedBox(height: 4),
                Text(
                  'Trial ends ${_formatDate(_status!['trialEndsAt'] as String)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
              if (!isInTrial && _status!['expiresAt'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Next billing: ${_formatDate(_status!['expiresAt'] as String)}',
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
            onTap: () => _startCheckout('monthly'),
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
            onTap: () => _startCheckout('annual'),
          ),
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
            'Opens Stripe Customer Portal — update payment method, view invoices, or cancel.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          // Cancel button — only for active subscriptions
          if (status == 'active') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _actionLoading ? null : () => _confirmCancel(context),
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: const Text('Cancel Subscription'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your access continues until the end of your billing period.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ],
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return VillageTheme.positive;
      case 'trial': return VillageTheme.primary;
      case 'past_due': return VillageTheme.warning;
      case 'expired': return VillageTheme.danger;
      case 'canceled': return Colors.grey;
      default: return Colors.grey;
    }
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

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[500])),
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
