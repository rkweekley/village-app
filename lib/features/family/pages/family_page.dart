import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/theme/village_theme.dart';
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
                color: VillageTheme.surfaceWarm,
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
                              color: VillageTheme.primaryTeal
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.share_rounded,
                                size: 20, color: VillageTheme.primaryTeal),
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
                          color: VillageTheme.primaryTeal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: VillageTheme.primaryTeal.withValues(alpha: 0.2),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.tag_rounded,
                                color: VillageTheme.primaryTeal, size: 20),
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
                              color: VillageTheme.primaryTeal,
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
                color: VillageTheme.surfaceWarm,
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
                              color: VillageTheme.primaryTeal
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.settings_rounded,
                                size: 20, color: VillageTheme.primaryTeal),
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

            // Members section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: VillageTheme.primaryTeal
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.people_rounded,
                        size: 16, color: VillageTheme.primaryTeal),
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
                  )),

            // Error
            if (familyState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VillageTheme.mealsCoral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: VillageTheme.mealsCoral.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: VillageTheme.mealsCoral, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          familyState.error!,
                          style: const TextStyle(
                              color: VillageTheme.mealsCoral, fontSize: 14),
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

    // Generate avatar color from name
    final nameHash = member.displayName.hashCode;
    final avatarColors = [
      VillageTheme.primaryTeal,
      VillageTheme.rewardsAmber,
      VillageTheme.mealsCoral,
      VillageTheme.calendarCyan,
      VillageTheme.shoppingPurple,
    ];
    final avatarColor = avatarColors[nameHash.abs() % avatarColors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: VillageTheme.surfaceWarm,
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
                            color: VillageTheme.primaryTeal
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: VillageTheme.primaryTeal,
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
                color: VillageTheme.primaryTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${member.pointsBalance} pts',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: VillageTheme.primaryTeal,
                ),
              ),
            ),
            if (canManage) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded,
                    color: Colors.grey[400]),
                onSelected: (value) {
                  // TODO: implement role change / remove member
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
