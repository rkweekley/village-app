import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/school/school_service.dart';
import 'package:village_app/features/family/family_provider.dart';
import 'package:village_app/features/family/models.dart';
import 'package:village_app/shared/widgets/adaptive_sheet.dart';

class SchoolPage extends ConsumerWidget {
  const SchoolPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsListProvider);
    final schoolWorkAsync = ref.watch(schoolWorkListProvider);
    final pendingGradingAsync = ref.watch(pendingGradingProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('School'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Assignments'),
              Tab(text: 'Subjects'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final tabIndex = DefaultTabController.of(context).index;
            if (tabIndex == 1) {
              _showCreateSubjectSheet(context, ref);
            } else {
              _showCreateAssignmentSheet(context, ref, subjectsAsync);
            }
          },
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            _AssignmentsTab(
              schoolWorkAsync: schoolWorkAsync,
              pendingGradingAsync: pendingGradingAsync,
              ref: ref,
            ),
            _SubjectsTab(
              subjectsAsync: subjectsAsync,
              ref: ref,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSubjectSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedColor;
    int sortOrder = 0;

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
                    child: const Icon(Icons.book_rounded,
                        color: VillageTheme.info, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('New Subject',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Subject name',
                  hintText: 'e.g. Math, Reading',
                  prefixIcon: const Icon(Icons.abc_outlined),
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
                controller: descCtrl,
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
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedColor,
                decoration: InputDecoration(
                  labelText: 'Color',
                  filled: true,
                  fillColor: VillageTheme.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(initialValue: null, child: Text('None')),
                  DropdownMenuItem(value: '#4CAF50', child: Text('Green')),
                  DropdownMenuItem(value: '#2196F3', child: Text('Blue')),
                  DropdownMenuItem(value: '#FF9800', child: Text('Orange')),
                  DropdownMenuItem(value: '#9C27B0', child: Text('Purple')),
                  DropdownMenuItem(value: '#F44336', child: Text('Red')),
                ],
                onChanged: (v) => setState(() => selectedColor = v),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  try {
                    await ref.read(schoolServiceProvider).createSubject(
                          name: name,
                          description: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          color: selectedColor,
                          sortOrder: sortOrder,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    ref.invalidate(subjectsListProvider);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: VillageTheme.info,
                ),
                child: const Text('Create Subject',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateAssignmentSheet(
      BuildContext context, WidgetRef ref, AsyncValue<List<Subject>> subjectsAsync) {
    final familyState = ref.read(familyProvider);
    final members = familyState.family?.members ?? [];
    final subjectsAvailable = subjectsAsync.asData?.value ?? [];

    if (subjectsAvailable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create at least one subject first.')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '10');
    String selectedSubjectId = subjectsAvailable.first.id;
    MemberInfo? selectedMember = members.isNotEmpty ? members.first : null;
    DateTime selectedDate = DateTime.now();

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
                  controller: titleCtrl,
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
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    filled: true,
                    fillColor: VillageTheme.surfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: subjectsAvailable
                      .map((s) => DropdownMenuItem(
                            initialValue: s.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _parseColor(s.color),
                                  radius: 8,
                                ),
                                const SizedBox(width: 8),
                                Text(s.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedSubjectId = v!),
                ),
                const SizedBox(height: 12),
                if (members.isNotEmpty)
                  DropdownButtonFormField<MemberInfo>(
                    initialValue: selectedMember,
                    decoration: InputDecoration(
                      labelText: 'Assign to',
                      filled: true,
                      fillColor: VillageTheme.surfaceBase,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: members
                        .map((m) => DropdownMenuItem(
                              initialValue: m,
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
                        controller: pointsCtrl,
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
                            fillColor: VillageTheme.surfaceBase,
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
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty) return;
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
                    await ref.read(schoolServiceProvider).createSchoolWork(
                          subjectId: selectedSubjectId,
                          assignedToId: selectedMember!.id,
                          title: titleCtrl.text,
                          description: descCtrl.text.isNotEmpty
                              ? descCtrl.text
                              : null,
                          dueDate: dueDate,
                          pointsPossible:
                              int.tryParse(pointsCtrl.text) ?? 10,
                        );
                    ref.invalidate(schoolWorkListProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
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
        ),
      ),
    );
  }

  Color _parseColor(String? color) {
    if (color == null || color.isEmpty) return VillageTheme.info;
    try {
      if (color.startsWith('#')) {
        final hex = color.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return VillageTheme.info;
  }
}

// ── Subjects Tab ──

class _SubjectsTab extends ConsumerWidget {
  final AsyncValue<List<Subject>> subjectsAsync;
  final WidgetRef ref;

  const _SubjectsTab({required this.subjectsAsync, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return subjectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (subjects) {
        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: VillageTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.book_rounded,
                      size: 40, color: VillageTheme.info),
                ),
                const SizedBox(height: 16),
                const Text('No subjects yet.',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Tap + to create one',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(subjectsListProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: subjects.length,
            itemBuilder: (ctx, i) {
              final subject = subjects[i];
              final subjColor = _subjectColor(subject.color);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: VillageTheme.surfaceCard,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: subjColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        subject.name.isNotEmpty
                            ? subject.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: subjColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  title: Text(subject.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Row(
                    children: [
                      Chip(
                        label: Text(
                          subject.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            color: subject.isActive
                                ? VillageTheme.positive
                                : Colors.grey,
                          ),
                        ),
                        backgroundColor: subject.isActive
                            ? VillageTheme.positive.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      if (subject.description != null &&
                          subject.description!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            subject.description!,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Text(
                    '${subject.sortOrder}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _subjectColor(String? color) {
    if (color == null || color.isEmpty) return VillageTheme.info;
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'deep_purple':
        return Colors.deepPurple;
      case 'indigo':
        return Colors.indigo;
      case 'blue':
        return Colors.blue;
      case 'light_blue':
        return Colors.lightBlue;
      case 'cyan':
        return Colors.cyan;
      case 'teal':
        return VillageTheme.positive;
      case 'green':
        return VillageTheme.positive;
      case 'light_green':
        return Colors.lightGreen;
      case 'lime':
        return Colors.lime;
      case 'yellow':
        return Colors.yellow;
      case 'amber':
        return VillageTheme.warning;
      case 'orange':
        return Colors.orange;
      case 'deep_orange':
        return Colors.deepOrange;
      case 'brown':
        return Colors.brown;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'blue_grey':
        return Colors.blueGrey;
      default:
        try {
          if (color.startsWith('#')) {
            final hex = color.replaceAll('#', '');
            return Color(int.parse('FF$hex', radix: 16));
          }
        } catch (_) {}
        return VillageTheme.info;
    }
  }
}

// ── Assignments Tab ──

class _AssignmentsTab extends ConsumerWidget {
  final AsyncValue<List<SchoolWork>> schoolWorkAsync;
  final AsyncValue<List<SchoolWork>> pendingGradingAsync;
  final WidgetRef ref;

  const _AssignmentsTab({
    required this.schoolWorkAsync,
    required this.pendingGradingAsync,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return schoolWorkAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assignments) {
        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: VillageTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.assignment_rounded,
                      size: 40, color: VillageTheme.info),
                ),
                const SizedBox(height: 16),
                const Text('No assignments yet.',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Tap + to create one',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(schoolWorkListProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: assignments.length,
            itemBuilder: (ctx, i) {
              final a = assignments[i];
              final statusColor = _statusColor(a.status);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: VillageTheme.surfaceCard,
                child: InkWell(
                  onTap: () => _showDetailSheet(context, a),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status indicator
                        Container(
                          width: 4,
                          height: 60,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    a.assignedToName,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.calendar_today,
                                      size: 13, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    a.dueDate,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Status chip
                                  _statusChip(a.status),
                                  const SizedBox(width: 8),
                                  // Points chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: a.gradePointsEarned != null
                                          ? VillageTheme.positive
                                              .withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      a.gradePointsEarned != null
                                          ? '${a.gradePointsEarned}/${a.pointsPossible} pts'
                                          : '${a.pointsPossible} pts',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: a.gradePointsEarned != null
                                            ? VillageTheme.positive
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (a.status == 'Pending')
                                    TextButton.icon(
                                      onPressed: () =>
                                          _showSubmitDialog(context, a.id),
                                      icon: const Icon(Icons.send_rounded,
                                          size: 16),
                                      label: const Text('Submit',
                                          style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            VillageTheme.info,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(status),
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog(BuildContext context, String assignmentId) {
    final noteCtrl = TextEditingController();
    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
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
                  child: const Icon(Icons.send_rounded,
                      color: VillageTheme.info, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Submit Assignment',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'Submission note (optional)',
                filled: true,
                fillColor: VillageTheme.surfaceBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.read(schoolServiceProvider).submitSchoolWork(
                      assignmentId,
                      submissionNote: noteCtrl.text.isNotEmpty
                          ? noteCtrl.text
                          : null,
                    );
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: VillageTheme.info,
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, SchoolWork a) {
    final isGraded = a.status == 'Graded';
    final canGrade = a.status == 'Submitted';

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: SingleChildScrollView(
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
                        color: VillageTheme.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_rounded,
                          color: VillageTheme.info, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(a.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow('Status', a.status),
                _detailRow('Assigned to', a.assignedToName),
                _detailRow('Due date', a.dueDate),
                _detailRow('Points possible', '${a.pointsPossible}'),
                if (a.description != null && a.description!.isNotEmpty)
                  _detailRow('Description', a.description!),
                if (a.submissionNote != null)
                  _detailRow('Submission note', a.submissionNote!),
                if (isGraded && a.gradePointsEarned != null)
                  _detailRow('Grade',
                      '${a.gradePointsEarned}/${a.pointsPossible}'),
                if (a.gradedAt != null) _detailRow('Graded at', a.gradedAt!),
                const SizedBox(height: 20),
                if (canGrade)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showGradeSheet(context, a.id, a.pointsPossible);
                    },
                    icon: const Icon(Icons.grading),
                    label: const Text('Grade'),
                    style: FilledButton.styleFrom(
                      backgroundColor: VillageTheme.info,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showGradeSheet(
      BuildContext context, String assignmentId, int pointsPossible) {
    final pointsCtrl =
        TextEditingController(text: pointsPossible.toString());
    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
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
                  child: const Icon(Icons.grading,
                      color: VillageTheme.positive, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Grade Assignment',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            Text('Points earned (out of $pointsPossible):',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: pointsCtrl,
              decoration: InputDecoration(
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
              onPressed: () {
                final points = int.tryParse(pointsCtrl.text);
                if (points == null || points < 0 || points > pointsPossible) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Enter a value between 0 and $pointsPossible'),
                    ),
                  );
                  return;
                }
                ref.read(schoolServiceProvider).gradeSchoolWork(
                      assignmentId,
                      pointsEarned: points,
                    );
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: VillageTheme.positive,
              ),
              child: const Text('Submit Grade',
                  style: TextStyle(fontSize: 16)),
            ),
          ],
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
