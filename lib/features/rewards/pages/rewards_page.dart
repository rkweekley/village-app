import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/features/rewards/rewards_service.dart';

class RewardsPage extends ConsumerWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsListProvider);
    final redemptionsAsync = ref.watch(redemptionsListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rewards'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateRewardDialog(context, ref),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available'),
              Tab(text: 'Redemptions'),
            ],
          ),
        ),
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Reward'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Reward name'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                TextField(
                  controller: costCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Point cost'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: ['Screen Time', 'Treat', 'Outing', 'Toy', 'Custom']
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => category = v!),
                ),
                TextField(
                  decoration: const InputDecoration(
                      labelText: 'Max redemptions (optional)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      maxRedemptions = int.tryParse(v),
                ),
                SwitchListTile(
                  title: const Text('Requires approval'),
                  value: requiresApproval,
                  onChanged: (v) => setState(() => requiresApproval = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                ref.read(rewardsServiceProvider).createReward(
                      name: nameCtrl.text,
                      description: descCtrl.text,
                      pointCost: int.tryParse(costCtrl.text) ?? 0,
                      category: category,
                      maxRedemptions: maxRedemptions,
                      requiresApproval: requiresApproval,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
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
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No rewards yet. Tap + to create one.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(rewardsListProvider.future),
          child: ListView.builder(
            itemCount: rewards.length,
            itemBuilder: (ctx, i) {
              final reward = rewards[i];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    child: Text('${reward.pointCost}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  title: Text(reward.name),
                  subtitle: Text(
                      '${reward.category} · ${reward.redemptionCount}/${reward.maxRedemptions ?? '∞'} redeemed'),
                  trailing: FilledButton.tonal(
                    onPressed: () => ref
                        .read(rewardsServiceProvider)
                        .redeemReward(reward.id),
                    child: const Text('Redeem'),
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
          return const Center(child: Text('No redemptions yet.'));
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(redemptionsListProvider.future),
          child: ListView.builder(
            itemCount: redemptions.length,
            itemBuilder: (ctx, i) {
              final r = redemptions[i];
              final isPending = r.status == 'Pending';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isPending ? Colors.amber : Colors.green,
                  child: Text('${r.pointsCost}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white)),
                ),
                title: Text(r.rewardName),
                subtitle: Text('${r.userName} · ${r.status}'),
                trailing: isPending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => ref
                                .read(rewardsServiceProvider)
                                .approveRedemption(r.id, true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => ref
                                .read(rewardsServiceProvider)
                                .approveRedemption(r.id, false),
                          ),
                        ],
                      )
                    : Icon(r.status == 'Approved'
                        ? Icons.check_circle
                        : Icons.cancel),
              );
            },
          ),
        );
      },
    );
  }
}
