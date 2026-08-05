import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/family/family_provider.dart';
import 'package:village_app/features/family/family_service.dart';
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
        centerTitle: true,
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
                elevation: 0,
                color: VillageTheme.surfaceCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: VillageTheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.share_rounded,
                                size: 20, color: VillageTheme.primary),
                          ),
                          const SizedBox(width: 10),
                          const Text('Invite Members',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Share this code with family members to join:',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: VillageTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: VillageTheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.tag_rounded,
                                color: VillageTheme.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                familyState.family!.inviteCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded),
                              tooltip: 'Copy invite code',
                              color: VillageTheme.primary,
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: familyState.family!.inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invite code copied!'),
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
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Family settings card
            if (familyState.family != null)
              Card(
                elevation: 0,
                color: VillageTheme.surfaceCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: VillageTheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.settings_rounded,
                                size: 20, color: VillageTheme.primary),
                          ),
                          const SizedBox(width: 10),
                          const Text('Family Settings',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _infoRow('Family Name', familyState.family!.name),
                      const Divider(height: 20),
                      _infoRow('Currency', familyState.family!.currencyName),
                      const Divider(height: 20),
                      _infoRow('Timezone', familyState.family!.timezone),
                      const Divider(height: 20),
                      _infoRow(
                          'Members', '${familyState.family!.members.length}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Subscription card
            _buildSubscriptionCard(context, familyState.family!),
            const SizedBox(height: 16),

            // Members section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: VillageTheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.people_rounded,
                        size: 16, color: VillageTheme.primary),
                  ),
                  const SizedBox(width: 10),
                  const Text('Family Members',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ],
              ),
            ),

            if (familyState.family == null && familyState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (familyState.family != null)
              ...familyState.family!.members.map((member) => _MemberCard(
                    member: member,
                    isCurrentUser: member.id == currentUserId,
                    role: authState.userInfo?.role ?? '',
                    onChanged: () => ref.invalidate(familyProvider),
                  )),

            // Error
            if (familyState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VillageTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: VillageTheme.danger.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: VillageTheme.danger, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          familyState.error!,
                          style: const TextStyle(
                              color: VillageTheme.danger, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, FamilyInfo family) {
    final status = family.subscriptionStatus ?? 'trial';
    final tier = family.subscriptionTier;
    final isTrial = status == 'trial';
    final isPastDue = status == 'past_due';

    Color statusColor;
    IconData statusIcon;
    String label;

    switch (status) {
      case 'active':
        statusColor = VillageTheme.positive;
        statusIcon = Icons.check_circle_rounded;
        label = tier == 'annual' ? 'Annual Plan' : 'Monthly Plan';
        break;
      case 'past_due':
        statusColor = VillageTheme.warning;
        statusIcon = Icons.error_outline_rounded;
        label = 'Payment Past Due';
        break;
      case 'expired':
        statusColor = VillageTheme.danger;
        statusIcon = Icons.cancel_rounded;
        label = 'Expired';
        break;
      case 'canceled':
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle_outline_rounded;
        label = 'Canceled';
        break;
      default:
        statusColor = VillageTheme.primary;
        statusIcon = Icons.timer_rounded;
        label = 'Free Trial';
        break;
    }

    return Card(
      elevation: 0,
      color: statusColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () => context.go('/subscription'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: statusColor)),
                    if (isTrial && family.trialEndsAt != null)
                      Text('Ends ${_formatDate(family.trialEndsAt!)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    if (!isTrial && family.subscriptionExpiresAt != null)
                      Text('Renews ${_formatDate(family.subscriptionExpiresAt!)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    if (isPastDue)
                      const Text('Update payment method →',
                          style: TextStyle(fontSize: 12, color: VillageTheme.warning, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _MemberCard extends ConsumerWidget {
  final MemberInfo member;
  final bool isCurrentUser;
  final String role;
  final VoidCallback onChanged;

  const _MemberCard({
    required this.member,
    required this.isCurrentUser,
    required this.role,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = role == 'Admin' || role == 'Parent';
    final canManage = isAdmin && !isCurrentUser;

    // Generate avatar color from name
    final nameHash = member.displayName.hashCode;
    final avatarColors = [
      VillageTheme.primary,
      VillageTheme.warning,
      VillageTheme.danger,
      VillageTheme.primaryLight,
      VillageTheme.primary,
    ];
    final avatarColor = avatarColors[nameHash.abs() % avatarColors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: VillageTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: avatarColor.withValues(alpha: 0.15),
              child: Text(
                member.displayName.isNotEmpty
                    ? member.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: avatarColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.displayName,
                        style: TextStyle(
                          fontWeight:
                              isCurrentUser ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: VillageTheme.primary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: VillageTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.role,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // Points
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: VillageTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${member.pointsBalance} pts',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: VillageTheme.primary,
                ),
              ),
            ),
            if (canManage) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded,
                    color: Colors.grey[400]),
                onSelected: (value) async {
                  final service = ref.read(familyServiceProvider);
                  try {
                    if (value == 'promote') {
                      final newRole =
                          member.role == 'Parent' ? 'Child' : 'Parent';
                      await service.changeMemberRole(member.id, newRole);
                    } else if (value == 'remove') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove Member'),
                          content: Text(
                              'Remove ${member.displayName} from the family?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await service.removeMember(member.id);
                      } else {
                        return;
                      }
                    }
                    onChanged();
                  } catch (_) {}
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'promote',
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Promote to Admin'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove_rounded,
                            size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove Member',
                            style: TextStyle(color: Colors.red)),
                      ],
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
