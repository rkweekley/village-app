import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/chores/chores_service.dart';
import 'package:village_app/features/school/school_service.dart';
import 'package:village_app/features/family/family_provider.dart';
import 'package:village_app/features/family/models.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/widgets/empty_state.dart';
import 'package:village_app/shared/widgets/adaptive_sheet.dart';

/// Combined Tasks page with Chores and School tabs.
class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isParent = ref.watch(authProvider).canManage;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tasks'),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
               Tab(
                 child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cleaning_services_outlined,
                        size: 18,
                        color: VillageTheme.positive),
                    const SizedBox(width: 6),
                    const Text('Chores'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined,
                        size: 18,
                        color: VillageTheme.info),
                    const SizedBox(width: 6),
                    const Text('School'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ChoresSection(ref: ref, isParent: isParent),
            _SchoolSection(ref: ref),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateChoice(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateChoice(BuildContext context, WidgetRef ref) {
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
                _showCreateChoreSheet(context, ref);
              },
              icon: const Icon(Icons.cleaning_services_rounded),
              label: const Text('New Chore'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: VillageTheme.positive,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showCreateAssignmentSheet(context, ref);
              },
              icon: const Icon(Icons.assignment_rounded),
              label: const Text('New Assignment'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: VillageTheme.info,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChoreSheet(BuildContext context, WidgetRef ref) {
    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CreateChoreSheet(ref: ref),
    );
  }

  void _showCreateAssignmentSheet(BuildContext context, WidgetRef ref) {
    final familyState = ref.read(familyProvider);
    final members = familyState.family?.members ?? [];
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No family members loaded. Visit Hub first.')),
      );
      return;
    }

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CreateAssignmentSheet(members: members, ref: ref),
    );
  }
}

// ── Chores Section ──

class _ChoresSection extends ConsumerWidget {
  final WidgetRef ref;
  final bool isParent;

  const _ChoresSection({required this.ref, required this.isParent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choresAsync = ref.watch(choresListProvider);

    return choresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (chores) => RefreshIndicator(
        onRefresh: () => ref.refresh(choresListProvider.future),
        child: chores.isEmpty
            ? EmptyState(
                icon: Icons.cleaning_services_outlined,
                title: 'No chores yet',
                subtitle: 'Tap + on the chores page to create one.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chores.length,
                itemBuilder: (ctx, i) => _ChoreCard(
                  chore: chores[i],
                  isParent: isParent,
                  ref: ref,
                ),
              ),
      ),
    );
  }
}

class _ChoreCard extends ConsumerWidget {
  final Chore chore;
  final bool isParent;
  final WidgetRef ref;

  const _ChoreCard({
    required this.chore,
    required this.isParent,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final diffColor = _difficultyColor(chore.difficulty);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showChoreDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Point badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${chore.pointValue}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: diffColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chore.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Tag(chore.difficulty, diffColor),
                        const SizedBox(width: 8),
                        _Tag(
                          chore.recurrence,
                          VillageTheme.primary,
                        ),
                        if (chore.requiresApproval) ...[
                          const SizedBox(width: 8),
                          _Tag('Needs approval', VillageTheme.danger),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // More button — available to everyone
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: Colors.grey[500]),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'complete', child: Text('Mark Complete')),
                  if (isParent)
                    const PopupMenuItem(value: 'assign', child: Text('Assign')),
                ],
                onSelected: (action) {
                  if (action == 'complete') {
                    _showQuickCompleteSheet(context);
                  } else if (action == 'assign') {
                    _showAssignSheet(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Easy':
        return VillageTheme.positive;
      case 'Medium':
        return VillageTheme.warning;
      case 'Hard':
        return VillageTheme.danger;
      default:
        return Colors.grey;
    }
  }

  void _showChoreDetail(BuildContext context) {
    showAdaptiveModalSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chore.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (chore.description != null && chore.description!.isNotEmpty)
              Text(chore.description!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            _detailChip('${chore.pointValue} pts', VillageTheme.warning),
            const SizedBox(width: 8),
            _detailChip(chore.difficulty, _difficultyColor(chore.difficulty)),
            const SizedBox(width: 8),
            _detailChip(chore.recurrence, VillageTheme.primary),
          ],
        ),
      ),
    );
  }

  void _showQuickCompleteSheet(BuildContext context) {
    final familyState = ref.read(familyProvider);
    final members = familyState.family?.members ?? [];

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No family members loaded. Visit Hub first.')),
      );
      return;
    }

    showAdaptiveModalSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          MemberInfo? selectedMember = members.first;
          DateTime selectedDate = DateTime.now();

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: VillageTheme.positive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_circle_outline,
                          color: VillageTheme.positive, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('Complete "${chore.name}"',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<MemberInfo>(
                  value: selectedMember,
                  decoration: InputDecoration(
                    labelText: 'Assign to',
                    filled: true,
                    fillColor: VillageTheme.surfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: members.map((m) => DropdownMenuItem(
                    value: m,
                    child: Row(
                      children: [
                        Icon(
                          m.role == 'Parent' ? Icons.star : Icons.person,
                          size: 18,
                          color: m.role == 'Parent'
                              ? VillageTheme.warning
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(m.displayName),
                        const Spacer(),
                        Text('${m.pointsBalance} pts',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedMember = v),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      helpText: 'Select due date',
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due date',
                      filled: true,
                      fillColor: VillageTheme.surfaceBase,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (selectedMember == null) return;
                      final dueDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                      try {
                        // Step 1: assign the chore
                        final assignResult = await ref.read(choresServiceProvider).assignChore(
                          chore.id,
                          selectedMember!.id,
                          dueDate,
                        );
                        final assignmentId = assignResult['id'] as String?;
                        if (assignmentId != null) {
                          // Step 2: mark it complete
                          await ref.read(choresServiceProvider).completeChore(assignmentId);
                        }
                        Navigator.pop(ctx);
                        ref.invalidate(choresListProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('"${chore.name}" marked as complete!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: VillageTheme.positive,
                    ),
                    child: const Text('Assign & Complete'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAssignSheet(BuildContext context) {
    final familyState = ref.read(familyProvider);
    final members = familyState.family?.members ?? [];

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No family members loaded. Visit Hub first.')),
      );
      return;
    }

    showAdaptiveModalSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          MemberInfo? selectedMember = members.first;
          DateTime selectedDate = DateTime.now();

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assign "${chore.name}"',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                DropdownButtonFormField<MemberInfo>(
                  value: selectedMember,
                  decoration: const InputDecoration(
                    labelText: 'Assign to',
                  ),
                  items: members.map((m) => DropdownMenuItem(
                    value: m,
                    child: Row(
                      children: [
                        Icon(
                          m.role == 'Parent' ? Icons.star : Icons.person,
                          size: 18,
                          color: m.role == 'Parent'
                              ? VillageTheme.warning
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(m.displayName),
                        const Spacer(),
                        Text('${m.pointsBalance} pts',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedMember = v),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      helpText: 'Select due date',
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (selectedMember == null) return;
                      final dueDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                      try {
                        await ref.read(choresServiceProvider).assignChore(
                          chore.id,
                          selectedMember!.id,
                          dueDate,
                        );
                        ref.invalidate(assignmentsListProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } on DioException {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Failed to assign chore. Check your connection.'),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Failed: $e'),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Assign'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _detailChip(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
  );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── School Section ──

class _SchoolSection extends ConsumerWidget {
  final WidgetRef ref;

  const _SchoolSection({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(schoolWorkListProvider);

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assignments) => RefreshIndicator(
        onRefresh: () => ref.refresh(schoolWorkListProvider.future),
        child: assignments.isEmpty
            ? EmptyState(
                icon: Icons.school_outlined,
                title: 'No assignments yet',
                subtitle: 'Tap + on the school page to create one.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: assignments.length,
                itemBuilder: (ctx, i) => _AssignmentCard(
                  assignment: assignments[i],
                  ref: ref,
                ),
              ),
      ),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  final SchoolWork assignment;
  final WidgetRef ref;

  const _AssignmentCard({required this.assignment, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(assignment.status);
    final statusIcon = _statusIcon(assignment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Tag(assignment.status, statusColor),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${assignment.dueDate}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Points & submit action
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: VillageTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${assignment.pointsPossible}pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: assignment.gradePointsEarned != null
                            ? VillageTheme.positive
                            : VillageTheme.info,
                      ),
                    ),
                  ),
                  if (assignment.status == 'Pending') ...[
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        onPressed: () => _submitAssignment(context),
                        icon: Icon(Icons.send_rounded,
                            color: VillageTheme.info, size: 20),
                        tooltip: 'Mark Submitted',
                        style: IconButton.styleFrom(
                          backgroundColor: VillageTheme.info.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitAssignment(BuildContext context) async {
    try {
      await ref.read(schoolServiceProvider).submitSchoolWork(assignment.id);
      ref.invalidate(schoolWorkListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${assignment.title}" submitted!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showDetail(BuildContext context) {
    final a = assignment;
    final isGraded = a.status == 'Graded';
    final canGrade = a.status == 'Submitted';
    final canSubmit = a.status == 'Pending';

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _infoRow('Status', a.status, _statusColor(a.status)),
            _infoRow('Assigned to', a.assignedToName, null),
            _infoRow('Due date', a.dueDate, null),
            _infoRow('Points possible', '${a.pointsPossible}', null),
            if (a.description != null && a.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(a.description!),
              ),
            if (isGraded && a.gradePointsEarned != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Grade: ${a.gradePointsEarned}/${a.pointsPossible}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: VillageTheme.positive,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (canSubmit)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _submitAssignment(context);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Mark Submitted'),
                  style: FilledButton.styleFrom(
                    backgroundColor: VillageTheme.info,
                  ),
                ),
              ),
            if (canSubmit && canGrade) const SizedBox(height: 12),
            if (canGrade)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showGradeSheet(context, a.id, a.pointsPossible);
                  },
                  icon: const Icon(Icons.grading),
                  label: const Text('Grade Assignment'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGradeSheet(BuildContext context, String id, int maxPoints) {
    final pointsCtrl = TextEditingController(text: maxPoints.toString());

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
                      color: VillageTheme.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.grading_rounded,
                        color: VillageTheme.info, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Grade Assignment',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Points earned (out of $maxPoints):',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pointsCtrl,
                decoration: InputDecoration(
                  labelText: 'Points',
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
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final pts = int.tryParse(pointsCtrl.text);
                  if (pts == null || pts < 0 || pts > maxPoints) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Enter 0-$maxPoints')),
                    );
                    return;
                  }
                  try {
                    await ref.read(schoolServiceProvider).gradeSchoolWork(id, pointsEarned: pts);
                    ref.invalidate(schoolWorkListProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on DioException {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Failed to grade assignment. Check your connection.'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Failed: $e'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: VillageTheme.info,
                ),
                child: const Text('Submit Grade',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return VillageTheme.warning;
      case 'Submitted':
        return VillageTheme.info;
      case 'Graded':
        return VillageTheme.positive;
      case 'Excused':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'Submitted':
        return Icons.send;
      case 'Graded':
        return Icons.check_circle;
      case 'Excused':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }
}

// ── Create Chore Sheet ──

/// Extracted StatefulWidget so TextEditingControllers are properly disposed.
class _CreateChoreSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _CreateChoreSheet({required this.ref});

  @override
  ConsumerState<_CreateChoreSheet> createState() => _CreateChoreSheetState();
}

class _CreateChoreSheetState extends ConsumerState<_CreateChoreSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointCtrl = TextEditingController(text: '10');
  String _recurrence = 'Once';
  String _difficulty = 'Easy';
  bool _requiresApproval = true;
  bool _requiresPhoto = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _pointCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                    color: VillageTheme.positive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cleaning_services_rounded,
                      color: VillageTheme.positive, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('New Chore',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Chore name',
                prefixIcon: const Icon(Icons.edit_outlined),
                filled: true,
                fillColor: VillageTheme.surfaceBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
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
              controller: _pointCtrl,
              decoration: InputDecoration(
                labelText: 'Point value',
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
              value: _recurrence,
              decoration: InputDecoration(
                labelText: 'Recurrence',
                prefixIcon: const Icon(Icons.repeat_outlined),
                filled: true,
                fillColor: VillageTheme.surfaceBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: ['Once', 'Daily', 'Weekly', 'Monthly']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _recurrence = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: InputDecoration(
                labelText: 'Difficulty',
                prefixIcon: const Icon(Icons.speed_rounded),
                filled: true,
                fillColor: VillageTheme.surfaceBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: ['Easy', 'Medium', 'Hard']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _difficulty = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Requires approval'),
              value: _requiresApproval,
              onChanged: (v) => setState(() => _requiresApproval = v),
              activeColor: VillageTheme.positive,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Requires photo'),
              value: _requiresPhoto,
              onChanged: (v) => setState(() => _requiresPhoto = v),
              activeColor: VillageTheme.positive,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (_nameCtrl.text.trim().isEmpty) return;
                await widget.ref.read(choresServiceProvider).createChore(
                      name: _nameCtrl.text.trim(),
                      description: _descCtrl.text.trim(),
                      pointValue: int.tryParse(_pointCtrl.text) ?? 10,
                      recurrence: _recurrence,
                      difficulty: _difficulty,
                      requiresApproval: _requiresApproval,
                      requiresPhoto: _requiresPhoto,
                    );
                widget.ref.invalidate(choresListProvider);
                if (context.mounted) Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: VillageTheme.positive,
              ),
              child: const Text('Create Chore',
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Assignment Sheet ──

/// Extracted StatefulWidget so TextEditingControllers are properly disposed.
class _CreateAssignmentSheet extends ConsumerStatefulWidget {
  final List<MemberInfo> members;
  final WidgetRef ref;
  const _CreateAssignmentSheet({required this.members, required this.ref});

  @override
  ConsumerState<_CreateAssignmentSheet> createState() =>
      _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState
    extends ConsumerState<_CreateAssignmentSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: '10');
  MemberInfo? _selectedMember;
  String? _selectedSubjectId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.members.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                    color: VillageTheme.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_rounded,
                      color: VillageTheme.info, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('New Assignment',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Title',
                prefixIcon: const Icon(Icons.edit_outlined),
                filled: true,
                fillColor: VillageTheme.surfaceBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            if (widget.members.isNotEmpty)
              DropdownButtonFormField<MemberInfo>(
                value: _selectedMember,
                decoration: InputDecoration(
                  labelText: 'Assign to',
                  filled: true,
                  fillColor: VillageTheme.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: widget.members
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
                onChanged: (v) => setState(() => _selectedMember = v),
              )
            else
              const Text('No family members loaded.',
                  style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final subjectsAsync = ref.watch(subjectsListProvider);
                final subjects = subjectsAsync.asData?.value ?? [];
                // Set default subject on first data arrival.
                if (_selectedSubjectId == null && subjects.isNotEmpty) {
                  _selectedSubjectId = subjects.first.id;
                }
                if (subjects.isNotEmpty) {
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedSubjectId,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          filled: true,
                          fillColor: VillageTheme.surfaceBase,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: subjects
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedSubjectId = v),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'No subjects yet — create one in School first.',
                    style: TextStyle(
                        color: VillageTheme.warning, fontSize: 13),
                  ),
                );
              },
            ),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pointsCtrl,
                    decoration: InputDecoration(
                      labelText: 'Points',
                      prefixIcon: const Icon(Icons.numbers_outlined),
                      filled: true,
                      fillColor: VillageTheme.surfaceBase,
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
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                        helpText: 'Select due date',
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due date',
                        filled: true,
                        fillColor: VillageTheme.surfaceBase,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon:
                            const Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                if (_titleCtrl.text.trim().isEmpty) return;
                if (_selectedMember == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Please assign to a family member.')),
                  );
                  return;
                }
                if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please select a subject.'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                  return;
                }
                final dueDate =
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
                try {
                  await widget.ref.read(schoolServiceProvider).createSchoolWork(
                        subjectId: _selectedSubjectId!,
                        assignedToId: _selectedMember!.id,
                        title: _titleCtrl.text.trim(),
                        description: _descCtrl.text.trim().isNotEmpty
                            ? _descCtrl.text.trim()
                            : null,
                        dueDate: dueDate,
                        pointsPossible:
                            int.tryParse(_pointsCtrl.text) ?? 10,
                      );
                  widget.ref.invalidate(schoolWorkListProvider);
                  if (context.mounted) Navigator.pop(context);
                } on DioException {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Failed to create assignment. Check your connection.'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: VillageTheme.info,
              ),
              child: const Text('Create Assignment',
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
