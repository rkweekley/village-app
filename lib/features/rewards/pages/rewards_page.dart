import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/rewards/rewards_service.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/features/family/family_provider.dart';
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
            _AvailableTab(rewardsAsync: rewardsAsync, ref: ref, isParent: isParent),
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
                        color: context.palette.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.card_giftcard_rounded,
                          color: context.palette.warning, size: 22),
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

void _showEditRewardDialog(
    BuildContext context, WidgetRef ref, Reward reward) {
  final nameCtrl = TextEditingController(text: reward.name);
  final descCtrl = TextEditingController(text: reward.description ?? '');
  final costCtrl = TextEditingController(text: reward.pointCost.toString());
  final maxRedemptionsCtrl = TextEditingController(
      text: reward.maxRedemptions?.toString() ?? '');
  String category = reward.category;
  bool requiresApproval = reward.requiresApproval;
  int? maxRedemptions = reward.maxRedemptions;

  // The backend serialises category as enum names (e.g. 'ScreenTime'), so
  // ensure the reward's stored value is a valid dropdown option.
  final categories = ['Screen Time', 'Treat', 'Outing', 'Toy', 'Custom'];
  if (!categories.contains(category)) {
    categories.add(category);
  }

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
                      color: context.palette.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit_rounded,
                        color: context.palette.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Edit Reward',
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
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => category = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxRedemptionsCtrl,
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
                    await ref.read(rewardsServiceProvider).updateReward(
                          reward.id,
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
                  backgroundColor: VillageTheme.primary,
                ),
                child: const Text('Save Changes',
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

Future<void> _confirmDeleteReward(
    BuildContext context, WidgetRef ref, Reward reward) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Reward'),
      content: Text('Delete "${reward.name}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: context.palette.danger),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;
  try {
    await ref.read(rewardsServiceProvider).deleteReward(reward.id);
    ref.invalidate(rewardsListProvider);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _AvailableTab extends StatelessWidget {
  final AsyncValue<List<Reward>> rewardsAsync;
  final WidgetRef ref;
  final bool isParent;
  const _AvailableTab({required this.rewardsAsync, required this.ref, required this.isParent});

  @override
  Widget build(BuildContext context) {
    return rewardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rewards) {
        if (rewards.isEmpty) {
          return EmptyState(
            icon: Icons.card_giftcard_rounded,
            title: 'No rewards yet',
            subtitle: isParent ? 'Tap + to create one' : 'Ask a parent to create rewards',
            iconBgColor: context.palette.warning,
            iconColor: context.palette.warning,
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
                        // Category icon + parent edit/delete menu
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _categoryColor(ctx, reward.category)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _categoryIcon(reward.category),
                                color: _categoryColor(ctx, reward.category),
                                size: 22,
                              ),
                            ),
                            const Spacer(),
                            if (isParent)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded,
                                    size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Reward options',
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditRewardDialog(
                                        context, ref, reward);
                                  } else if (value == 'delete') {
                                    _confirmDeleteReward(
                                        context, ref, reward);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            size: 18,
                                            color: context.palette.danger),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style: TextStyle(
                                                color: context.palette.danger)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
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
                            color: context.palette.warning
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars_rounded,
                                  size: 14, color: context.palette.warning),
                              const SizedBox(width: 4),
                              Text(
                                '${reward.pointCost} ${ref.read(familyProvider).family?.currencyName ?? 'pts'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.palette.warning,
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
                                      'Spend ${reward.pointCost} ${ref.read(familyProvider).family?.currencyName ?? 'points'} on "${reward.name}"?'),
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

  Color _categoryColor(BuildContext context, String category) {
    switch (category) {
      case 'Screen Time':
        return context.palette.info;
      case 'Treat':
        return context.palette.danger;
      case 'Outing':
        return VillageTheme.primaryLight;
      case 'Toy':
        return context.palette.primary;
      default:
        return context.palette.warning;
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
          return EmptyState(
            icon: Icons.history_rounded,
            title: 'No redemptions yet',
            iconBgColor: context.palette.warning,
            iconColor: context.palette.warning,
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
                              ? context.palette.warning.withValues(alpha: 0.12)
                              : isApproved
                                  ? context.palette.positive
                                      .withValues(alpha: 0.12)
                                  : context.palette.danger
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
                              ? context.palette.warning
                              : isApproved
                                  ? context.palette.positive
                                  : context.palette.danger,
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
                                color: context.palette.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.palette.warning
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${r.pointsCost} ${ref.read(familyProvider).family?.currencyName ?? 'pts'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.palette.warning,
                          ),
                        ),
                      ),
                      if (isPending) const SizedBox(width: 8),
                      if (isPending)
                        IconButton(
                          icon: Icon(Icons.check_circle_rounded,
                              color: context.palette.positive),
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
                          icon: Icon(Icons.cancel_rounded,
                              color: context.palette.danger),
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
