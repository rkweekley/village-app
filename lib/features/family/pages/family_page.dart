import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/features/family/family_provider.dart';
import 'package:village_app/features/family/models.dart';

class FamilyPage extends ConsumerStatefulWidget {
  const FamilyPage({super.key});

  @override
  ConsumerState<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends ConsumerState<FamilyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyProvider.notifier).loadFamily();
    });
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.userInfo?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(familyState.family?.name ?? 'Family'),
        actions: [
          if (familyState.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(familyProvider.notifier).loadFamily(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Invite code card
            if (familyState.family != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.share,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Invite Members',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Share this code with family members to join:',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.tag,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                familyState.family!.inviteCode,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                    ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy invite code',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: familyState.family!.inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Invite code copied!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New members enter this code when creating their account.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            ],

            // Family info card
            if (familyState.family != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Family Settings',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _infoRow(
                        context,
                        'Family Name',
                        familyState.family!.name,
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        'Currency',
                        familyState.family!.currencyName,
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        'Timezone',
                        familyState.family!.timezone,
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        'Members',
                        '${familyState.family!.members.length}',
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Members section
            Text('Family Members',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            if (familyState.family == null && familyState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (familyState.family != null)
              ...familyState.family!.members.map((member) =>
                  _MemberCard(
                    member: member,
                    isCurrentUser: member.id == currentUserId,
                    role: authState.userInfo?.role ?? '',
                  )),

            // Error
            if (familyState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
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
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  final MemberInfo member;
  final bool isCurrentUser;
  final String role;

  const _MemberCard({
    required this.member,
    required this.isCurrentUser,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'Admin' || role == 'Parent';
    final canManage = isAdmin && !isCurrentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            member.displayName.isNotEmpty
                ? member.displayName[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCurrentUser
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : null,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              member.displayName,
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'You',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          member.role,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${member.pointsBalance} pts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            if (canManage) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  // TODO: implement role change / remove member
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'promote',
                    child: ListTile(
                      leading: Icon(Icons.star),
                      title: Text('Promote to Admin'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(Icons.person_remove, color: Colors.red),
                      title: Text('Remove Member',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
