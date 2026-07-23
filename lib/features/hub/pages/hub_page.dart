import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/features/family/family_provider.dart';
import 'package:village_app/core/auth/auth_provider.dart';

class HubPage extends ConsumerStatefulWidget {
  const HubPage({super.key});

  @override
  ConsumerState<HubPage> createState() => _HubPageState();
}

class _HubPageState extends ConsumerState<HubPage> {
  @override
  void initState() {
    super.initState();
    // Trigger family load if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyProvider.notifier).loadFamily();
    });
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.userInfo?.id;

    // Find current user's points from members
    int myPoints = 0;
    String myName = authState.userInfo?.displayName ?? 'You';
    String familyName = 'Village';

    if (familyState.family != null) {
      familyName = familyState.family!.name;
      if (currentUserId != null) {
        final me = familyState.family!.members
            .where((m) => m.id == currentUserId)
            .firstOrNull;
        if (me != null) {
          myPoints = me.pointsBalance;
          myName = me.displayName;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(familyState.isLoading ? 'Loading...' : familyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: navigate to profile/settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(familyProvider.notifier).loadFamily(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to $familyName',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your family productivity hub',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Points summary card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.stars,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('My Points',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    familyState.isLoading
                                        ? '...'
                                        : myPoints.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            if (familyState.isLoading)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Leaderboard (shown when family data is loaded)
                    if (familyState.family != null &&
                        familyState.family!.members.length > 1) ...[
                      const SizedBox(height: 16),
                      Text('Family Leaderboard',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: _buildLeaderboard(
                              context,
                              familyState.family!.members
                                ..sort(
                                    (a, b) => b.pointsBalance.compareTo(a.pointsBalance)),
                              currentUserId,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Error banner
                    if (familyState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    familyState.error!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Quick actions
                    Text('Quick Actions',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                delegate: SliverChildListDelegate([
                  _QuickActionCard(
                    icon: Icons.checklist,
                    label: 'Chores',
                    color: Colors.green,
                    onTap: () => context.go('/chores'),
                  ),
                  _QuickActionCard(
                    icon: Icons.stars,
                    label: 'Rewards',
                    color: Colors.orange,
                    onTap: () => context.go('/rewards'),
                  ),
                  _QuickActionCard(
                    icon: Icons.calendar_month,
                    label: 'Calendar',
                    color: Colors.blue,
                    onTap: () => context.go('/calendar'),
                  ),
                  _QuickActionCard(
                    icon: Icons.shopping_cart,
                    label: 'Shopping',
                    color: Colors.purple,
                    onTap: () => context.go('/shopping'),
                  ),
                ]),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLeaderboard(
    BuildContext context,
    List members,
    String? currentUserId,
  ) {
    final sorted = List.from(members)
      ..sort((a, b) => b.pointsBalance.compareTo(a.pointsBalance));

    final medals = ['🥇', '🥈', '🥉'];

    return List.generate(sorted.length, (i) {
      final member = sorted[i];
      final isMe = member.id == currentUserId;

      return Container(
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          dense: true,
          leading: Text(
            i < 3 ? medals[i] : '#${i + 1}',
            style: const TextStyle(fontSize: 18),
          ),
          title: Text(
            member.displayName,
            style: TextStyle(
              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: Text(
            '${member.pointsBalance}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      );
    });
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
