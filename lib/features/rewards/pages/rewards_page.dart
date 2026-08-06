import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/rewards/rewards_service.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/widgets/empty_state.dart';
import 'package:village_app/shared/widgets/adaptive_sheet.dart';

class RewardsPage extends ConsumerWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsListProvider);
    final redemptionsAsync = ref.watch(redemptionsListProvider);
    final isParent = ref.watch(authProvider).canManage;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rewards Shop'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Available'),
              Tab(text: 'Redemptions'),
            ],
          ),
        ),
        floatingActionButton: isParent
            ? FloatingActionButton(
                onPressed: () => _showCreateRewardDialog(context, ref),
                child: const Icon(Icons.add),
              )
            : null,
        body: TabBarView(
          children: [
            _AvailableTab(rewardsAsync: rewardsAsync, ref: ref),
            _RedemptionsTab(redemptionsAsync: redemptionsAsync, ref: ref),
          ],
        ),
      ),
    );
  }

  void _showCreateRewardDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    String category = 'Custom';
    bool requiresApproval = true;
    int? maxRedemptions;

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: VillageTheme.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.card_giftcard_rounded,
                          color: VillageTheme.warning, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text('New Reward',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reward name',
                    prefixIcon: const Icon(Icons.emoji_events_outlined),
                    filled: true,
                    fillColor: VillageTheme.surfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description_outlined),
                    filled: true,
                    fillColor: VillageTheme.surfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costCtrl,
                  decoration: InputDecoration(
                    labelText: 'Point cost',
                    prefixIcon: const Icon(Icons.stars_rounded),
                    filled: true,
                    fillColor: VillageTheme.surfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    filled: true,
                    fillColor: VillageTheme.surfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Screen Time', 'Treat', 'Outing', 'Toy', 'Custom']
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Max redemptions (optional)',
                    prefixIcon: const Icon(Icons.repeat_outlined),
                    filled: true,
                    fillColor: VillageTheme.surfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => maxRedemptions = int.tryParse(v),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Requires approval'),
                  value: requiresApproval,
                  onChanged: (v) => setState(() => requiresApproval = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    try {
                      await ref.read(rewardsServiceProvider).createReward(
                            name: nameCtrl.text,
                            description: descCtrl.text,
                            pointCost: int.tryParse(costCtrl.text) ?? 0,
                            category: category,
                            maxRedemptions: maxRedemptions,
                            requiresApproval: requiresApproval,
                          );
                      ref.invalidate(rewardsListProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Failed: $e'),
                              backgroundColor: Colors.red.shade700,
                              behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: VillageTheme.warning,
                  ),
                  child: const Text('Create Reward',
                      style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableTab extends StatelessWidget {
  final AsyncValue<List<Reward>> rewardsAsync;
  final WidgetRef ref;
  const _AvailableTab({required this.rewardsAsync, required this.ref});

  @override
  Widget build(BuildContext context) {
    return rewardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rewards) {
        if (rewards.isEmpty) {
          return const EmptyState(
            icon: Icons.card_giftcard_rounded,
            title: 'No rewards yet',
            subtitle: 'Tap + to create one',
            iconBgColor: VillageTheme.warning,
            iconColor: VillageTheme.warning,
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(rewardsListProvider.future),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: rewards.length,
              itemBuilder: (ctx, i) {
                final reward = rewards[i];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  color: VillageTheme.surfaceCard,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _categoryColor(reward.category)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _categoryIcon(reward.category),
                            color: _categoryColor(reward.category),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          reward.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        // Point cost badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: VillageTheme.warning
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded,
                                  size: 14, color: VillageTheme.warning),
                              const SizedBox(width: 4),
                              Text(
                                '${reward.pointCost} pts',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: VillageTheme.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: FilledButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Redeem Reward'),
                                  content: Text(
                                      'Spend ${reward.pointCost} points on "${reward.name}"?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Redeem')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await ref
                                      .read(rewardsServiceProvider)
                                      .redeemReward(reward.id);
                                  ref.invalidate(rewardsListProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Failed to redeem: $e')),
                                    );
                                  }
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: VillageTheme.warning,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Redeem',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Screen Time':
        return VillageTheme.info;
      case 'Treat':
        return VillageTheme.danger;
      case 'Outing':
        return VillageTheme.primaryLight;
      case 'Toy':
        return VillageTheme.primary;
      default:
        return VillageTheme.warning;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Screen Time':
        return Icons.tablet_rounded;
      case 'Treat':
        return Icons.icecream_rounded;
      case 'Outing':
        return Icons.directions_walk_rounded;
      case 'Toy':
        return Icons.toys_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }
}

class _RedemptionsTab extends StatelessWidget {
  final AsyncValue<List<RewardRedemption>> redemptionsAsync;
  final WidgetRef ref;
  const _RedemptionsTab(
      {required this.redemptionsAsync, required this.ref});

  @override
  Widget build(BuildContext context) {
    return redemptionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (redemptions) {
        if (redemptions.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No redemptions yet',
            iconBgColor: VillageTheme.warning,
            iconColor: VillageTheme.warning,
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(redemptionsListProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: redemptions.length,
            itemBuilder: (ctx, i) {
              final r = redemptions[i];
              final isPending = r.status == 'Pending';
              final isApproved = r.status == 'Approved';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: VillageTheme.surfaceCard,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isPending
                              ? VillageTheme.warning.withValues(alpha: 0.12)
                              : isApproved
                                  ? VillageTheme.positive
                                      .withValues(alpha: 0.12)
                                  : VillageTheme.danger
                                      .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isPending
                              ? Icons.hourglass_empty_rounded
                              : isApproved
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                          color: isPending
                              ? VillageTheme.warning
                              : isApproved
                                  ? VillageTheme.positive
                                  : VillageTheme.danger,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.rewardName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${r.userName} · ${r.status}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: VillageTheme.warning
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${r.pointsCost} pts',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: VillageTheme.warning,
                          ),
                        ),
                      ),
                      if (isPending) const SizedBox(width: 8),
                      if (isPending)
                        IconButton(
                          icon: const Icon(Icons.check_circle_rounded,
                              color: VillageTheme.positive),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(rewardsServiceProvider)
                                  .approveRedemption(r.id, true);
                              ref.invalidate(redemptionsListProvider);
                              ref.invalidate(rewardsListProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Redemption approved ✓')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error: $e')),
                                );
                              }
                            }
                          },
                        ),
                      if (isPending)
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded,
                              color: VillageTheme.danger),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(rewardsServiceProvider)
                                  .approveRedemption(r.id, false);
                              ref.invalidate(redemptionsListProvider);
                              ref.invalidate(rewardsListProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Redemption rejected')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
              );
            },
          ),
        );
      },
    );
  }
}
