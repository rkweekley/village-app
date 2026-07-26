import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/chores/chores_service.dart';
import 'package:village_app/features/school/school_service.dart';
import 'package:village_app/features/family/family_provider.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/features/notifications/notification_service.dart';
import 'package:village_app/features/family/models.dart';
import 'package:village_app/shared/widgets/adaptive_sheet.dart';

class HubPage extends ConsumerStatefulWidget {
  const HubPage({super.key});

  @override
  ConsumerState<HubPage> createState() => _HubPageState();
}

class _HubPageState extends ConsumerState<HubPage> {
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
    final theme = Theme.of(context);

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
        centerTitle: true,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(notificationProvider);
              return Badge(
                isLabelVisible: state.unreadCount > 0,
                label: Text(
                  state.unreadCount > 99 ? '99+' : state.unreadCount.toString(),
                  style: const TextStyle(fontSize: 10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/notifications'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Family',
            onPressed: () => context.go('/family'),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(familyProvider.notifier).loadFamily(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              children: [
                // ── Welcome banner ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VillageTheme.primaryTeal,
                    VillageTheme.primaryTeal.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $myName 👋',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    familyState.isLoading
                        ? 'Loading your family...'
                        : '$familyName is waiting for you',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Points card ──
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              color: VillageTheme.surfaceWarm,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: VillageTheme.rewardsAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.stars_rounded,
                        size: 32,
                        color: VillageTheme.rewardsAmber,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Points',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            familyState.isLoading ? '...' : myPoints.toString(),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: VillageTheme.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (familyState.isLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Quick Actions (Bento Grid) ──
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildBentoGrid(context),

            // ── Leaderboard ──
            if (familyState.family != null &&
                familyState.family!.members.length > 1) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.leaderboard_rounded,
                      size: 22, color: VillageTheme.rewardsAmber),
                  const SizedBox(width: 8),
                  Text(
                    'Family Leaderboard',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLeaderboardCard(
                context,
                familyState.family!.members,
                currentUserId,
              ),
            ],

            // ── Error banner ──
            if (familyState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: theme.colorScheme.errorContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: theme.colorScheme.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            familyState.error!,
                            style: TextStyle(
                                color: theme.colorScheme.onErrorContainer),
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
          // ── FAB overlay ──
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _showCreateChoice(context),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context) {

    // Define bento items: each has icon, label, color, route
    // Layout: 2 columns, first row has a 2-col-wide item + 1-col item,
    // second row has 1-col + 1-col + 2-col-wide item
    return Column(
      children: [
        // Row 1: Chores (2 cols) + Rewards (1 col)
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _BentoActionCard(
                icon: Icons.checklist_rounded,
                label: 'Chores',
                color: VillageTheme.choresGreen,
                onTap: () => context.push('/chores'),
                tall: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _BentoActionCard(
                icon: Icons.stars_rounded,
                label: 'Rewards',
                color: VillageTheme.rewardsAmber,
                onTap: () => context.push('/rewards'),
                tall: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Calendar (1 col) + Shopping (1 col) + School (2 cols)
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _BentoActionCard(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                color: VillageTheme.calendarCyan,
                onTap: () => context.go('/calendar'),
                tall: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _BentoActionCard(
                icon: Icons.shopping_cart_rounded,
                label: 'Shopping',
                color: VillageTheme.shoppingPurple,
                onTap: () => context.go('/shopping'),
                tall: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _BentoActionCard(
                icon: Icons.school_rounded,
                label: 'School',
                color: VillageTheme.schoolBlue,
                onTap: () => context.push('/school'),
                tall: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 3: Meals (full width)
        _BentoActionCard(
          icon: Icons.restaurant_rounded,
          label: 'Meals',
          color: VillageTheme.mealsCoral,
          onTap: () => context.push('/meals'),
          tall: false,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(
    BuildContext context,
    List<MemberInfo> members,
    String? currentUserId,
  ) {
    final theme = Theme.of(context);
    final sorted = List<MemberInfo>.from(members)
      ..sort((a, b) => b.pointsBalance.compareTo(a.pointsBalance));
    final medals = ['🥇', '🥈', '🥉'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: VillageTheme.surfaceWarm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: List.generate(sorted.length, (i) {
            final member = sorted[i];
            final isMe = member.id == currentUserId;
            return Container(
              decoration: BoxDecoration(
                color: isMe
                    ? VillageTheme.primaryTeal.withValues(alpha: 0.08)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: ListTile(
                dense: true,
                leading: SizedBox(
                  width: 32,
                  child: Text(
                    i < 3 ? medals[i] : '#${i + 1}',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                title: Text(
                  member.displayName,
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: VillageTheme.rewardsAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${member.pointsBalance} pts',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: VillageTheme.rewardsAmber,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Create Task FAB methods ──

  void _showCreateChoice(BuildContext context) {
    showAdaptiveModalSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Create…',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showCreateChoreSheet(context);
              },
              icon: const Icon(Icons.cleaning_services_rounded),
              label: const Text('New Chore'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: VillageTheme.choresGreen,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showCreateAssignmentSheet(context);
              },
              icon: const Icon(Icons.assignment_rounded),
              label: const Text('New Assignment'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: VillageTheme.schoolBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChoreSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointCtrl = TextEditingController(text: '10');
    String recurrence = 'Once';
    String difficulty = 'Easy';
    bool requiresApproval = true;
    bool requiresPhoto = false;

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
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
                        color: VillageTheme.choresGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.cleaning_services_rounded,
                          color: VillageTheme.choresGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text('New Chore',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Chore name',
                    prefixIcon: const Icon(Icons.edit_outlined),
                    filled: true,
                    fillColor: VillageTheme.backgroundWarm,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description_outlined),
                    filled: true,
                    fillColor: VillageTheme.backgroundWarm,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointCtrl,
                  decoration: InputDecoration(
                    labelText: 'Point value',
                    prefixIcon: const Icon(Icons.stars_rounded),
                    filled: true,
                    fillColor: VillageTheme.backgroundWarm,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: recurrence,
                  decoration: InputDecoration(
                    labelText: 'Recurrence',
                    prefixIcon: const Icon(Icons.repeat_outlined),
                    filled: true,
                    fillColor: VillageTheme.backgroundWarm,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Once', 'Daily', 'Weekly', 'Monthly']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => recurrence = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: difficulty,
                  decoration: InputDecoration(
                    labelText: 'Difficulty',
                    prefixIcon: const Icon(Icons.speed_rounded),
                    filled: true,
                    fillColor: VillageTheme.backgroundWarm,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Easy', 'Medium', 'Hard']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => difficulty = v!),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Requires approval'),
                  value: requiresApproval,
                  onChanged: (v) => setState(() => requiresApproval = v),
                  activeColor: VillageTheme.choresGreen,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Requires photo'),
                  value: requiresPhoto,
                  onChanged: (v) => setState(() => requiresPhoto = v),
                  activeColor: VillageTheme.choresGreen,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    ref.read(choresServiceProvider).createChore(
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          pointValue: int.tryParse(pointCtrl.text) ?? 10,
                          recurrence: recurrence,
                          difficulty: difficulty,
                          requiresApproval: requiresApproval,
                          requiresPhoto: requiresPhoto,
                        );
                    Navigator.pop(ctx);
                    ref.invalidate(choresListProvider);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: VillageTheme.choresGreen,
                  ),
                  child: const Text('Create Chore',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateAssignmentSheet(BuildContext context) {
    final familyState = ref.read(familyProvider);
    final members = familyState.family?.members ?? [];
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No family members loaded. Visit Hub first.')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '10');
    MemberInfo? selectedMember = members.first;
    DateTime selectedDate = DateTime.now();

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
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
                        color: VillageTheme.schoolBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_rounded,
                          color: VillageTheme.schoolBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text('New Assignment',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    prefixIcon: const Icon(Icons.edit_outlined),
                    filled: true,
                    fillColor: VillageTheme.backgroundWarm,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                if (members.isNotEmpty)
                  DropdownButtonFormField<MemberInfo>(
                    value: selectedMember,
                    decoration: InputDecoration(
                      labelText: 'Assign to',
                      filled: true,
                      fillColor: VillageTheme.backgroundWarm,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: members
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Row(
                                children: [
                                  Icon(
                                    m.role == 'Parent'
                                        ? Icons.star
                                        : Icons.person,
                                    size: 18,
                                    color: m.role == 'Parent'
                                        ? Colors.amber
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(m.displayName),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selectedMember = v),
                  )
                else
                  const Text('No family members loaded.',
                      style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: const Icon(Icons.description_outlined),
                    filled: true,
                    fillColor: VillageTheme.backgroundWarm,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pointsCtrl,
                        decoration: InputDecoration(
                          labelText: 'Points',
                          prefixIcon: const Icon(Icons.numbers_outlined),
                          filled: true,
                          fillColor: VillageTheme.backgroundWarm,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                            helpText: 'Select due date',
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Due date',
                            filled: true,
                            fillColor: VillageTheme.backgroundWarm,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon:
                                const Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    if (selectedMember == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please assign to a family member.')),
                      );
                      return;
                    }
                    final dueDate =
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                    ref.read(schoolServiceProvider).createSchoolWork(
                          subjectId: '', // user picks subject later
                          assignedToId: selectedMember!.id,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isNotEmpty
                              ? descCtrl.text.trim()
                              : null,
                          dueDate: dueDate,
                          pointsPossible:
                              int.tryParse(pointsCtrl.text) ?? 10,
                        );
                    Navigator.pop(ctx);
                    ref.invalidate(schoolWorkListProvider);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: VillageTheme.schoolBlue,
                  ),
                  child: const Text('Create Assignment',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BentoActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool tall;
  final bool fullWidth;

  const _BentoActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.tall = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: VillageTheme.surfaceWarm,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: tall ? 140 : 88,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: tall ? 48 : 40,
                height: tall ? 48 : 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: tall ? 24 : 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
