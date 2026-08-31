import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/chores/chores_service.dart';
import 'package:village_app/features/family/family_provider.dart';
import 'package:village_app/features/family/models.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/widgets/empty_state.dart';
import 'package:village_app/shared/widgets/adaptive_sheet.dart';
import 'package:village_app/shared/widgets/create_chore_sheet.dart';
import 'package:village_app/shared/widgets/create_project_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/shared/utils/status_color.dart';

class ChoresPage extends ConsumerStatefulWidget {
  const ChoresPage({super.key});

  @override
  ConsumerState<ChoresPage> createState() => _ChoresPageState();
}

class _ChoresPageState extends ConsumerState<ChoresPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    final tabCount = ref.read(authProvider).canManage ? 3 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final choresAsync = ref.watch(choresListProvider);
    final assignmentsAsync = ref.watch(assignmentsListProvider);
    final isParent = ref.watch(authProvider).canManage;
    final userId = ref.watch(authProvider).userInfo?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Chores'),
            const Tab(text: 'Assignments'),
            if (isParent) const Tab(text: 'Approvals'),
          ],
        ),
      ),
      floatingActionButton: _currentTab == 2
          ? null // No FAB on Approvals tab
          : FloatingActionButton(
              heroTag: const ObjectKey('choresPageFAB'),
              onPressed: () {
                if (_currentTab == 0) {
                  _showCreateMenu(context);
                } else if (_currentTab == 1) {
                  _showCreateAssignmentDialog(context);
                }
              },
              child: const Icon(Icons.add),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChoresTab(choresAsync: choresAsync, ref: ref, userId: userId, isParent: isParent),
          _AssignmentsTab(
              assignmentsAsync: assignmentsAsync, ref: ref),
          if (isParent)
            _ApprovalsTab(
                assignmentsAsync: assignmentsAsync, ref: ref),
        ],
      ),
    );
  }

  // ── Create Menu (Project vs Chore) ──

  Future<void> _showCreateMenu(BuildContext context) async {
    final choice = await showAdaptiveModalSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.folder_outlined,
                  color: context.palette.positive),
              title: const Text('New Project'),
              subtitle: const Text('A container with its own task list'),
              onTap: () => Navigator.pop(ctx, 'project'),
            ),
            ListTile(
              leading: Icon(Icons.cleaning_services_rounded,
                  color: context.palette.positive),
              title: const Text('New Chore'),
              subtitle: const Text('A standalone chore'),
              onTap: () => Navigator.pop(ctx, 'chore'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    if (choice == 'project') {
      final projectId = await showCreateProjectSheet(context, ref);
      if (projectId != null && context.mounted) {
        context.push('/chores/projects/$projectId');
      }
    } else if (choice == 'chore') {
      await showCreateChoreSheet(context, ref);
    }
  }

  // ── Create Assignment ──

  void _showCreateAssignmentDialog(BuildContext context) {
    final familyState = ref.read(familyProvider);
    final members = familyState.family?.members ?? [];
    final allChores = ref.read(choresListProvider).asData?.value ?? [];
    // Projects/containers group subtasks and can't be assigned directly.
    final choresData = allChores.where((c) => !c.hasChildren).toList();

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No family members loaded. Visit Hub to load your family.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (choresData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No assignable chores yet. Create some chores first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CreateAssignmentSheet(
        chores: choresData,
        members: members,
        ref: ref,
        onAssign: (choreId, assignedToId, dueDate) async {
          await ref.read(choresServiceProvider).assignChore(
                choreId,
                assignedToId,
                dueDate,
              );
          ref.invalidate(assignmentsListProvider);
        },
      ),
    );
  }
}

// ── Create Assignment Sheet (standalone stateful widget) ──

class _CreateAssignmentSheet extends StatefulWidget {
  final List<Chore> chores;
  final List<MemberInfo> members;
  final WidgetRef ref;
  final Future<void> Function(String choreId, String assignedToId, String dueDate)
      onAssign;

  const _CreateAssignmentSheet({
    required this.chores,
    required this.members,
    required this.ref,
    required this.onAssign,
  });

  @override
  State<_CreateAssignmentSheet> createState() => _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends State<_CreateAssignmentSheet> {
  final _choreCtrl = TextEditingController();
  Chore? _selectedChore;
  MemberInfo? _selectedMember;
  DateTime _selectedDate = DateTime.now();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.members.first;
  }

  @override
  void dispose() {
    _choreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _selectedMember ??= widget.members.first;

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
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.palette.positive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.assignment_rounded,
                      color: context.palette.positive, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('New Assignment',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),

            // Chore picker (search/select)
            Autocomplete<Chore>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return widget.chores;
                }
                return widget.chores.where((chore) => chore.name
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
                displayStringForOption: (chore) => chore.name,
                onSelected: (chore) {
                  setState(() => _selectedChore = chore);
                },
                fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: _selectedChore != null
                          ? 'Chore: ${_selectedChore!.name}'
                          : 'Search chores...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _selectedChore != null
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                controller.clear();
                                setState(() => _selectedChore = null);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: context.palette.surfaceBase,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() => _selectedChore = null),
                  );
                },
                optionsViewBuilder: (ctx, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (ctx, i) {
                            final chore = options.elementAt(i);
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    context.palette.positive.withValues(alpha: 0.15),
                                child: Text('${chore.pointValue}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.palette.positive)),
                              ),
                              title: Text(chore.name,
                                  style: const TextStyle(fontSize: 14)),
                              subtitle: Text(
                                '${chore.recurrence} · ${chore.difficulty}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () => onSelected(chore),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Member picker
              DropdownButtonFormField<MemberInfo>(
                value: _selectedMember,
                decoration: InputDecoration(
                  labelText: 'Assign to',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: context.palette.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: widget.members
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
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
                              Text(
                                '${m.pointsBalance} ${widget.ref.read(familyProvider).family?.currencyName ?? 'pts'}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMember = v),
              ),
              const SizedBox(height: 12),

              // Date picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 1)),
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
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    filled: true,
                    fillColor: context.palette.surfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  child: Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit
              FilledButton(
                onPressed: _selectedChore == null || _submitting
                    ? null
                    : () async {
                        setState(() => _submitting = true);
                        try {
                          final dueDate =
                              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
                          await widget.onAssign(
                            _selectedChore!.id,
                            _selectedMember!.id,
                            dueDate,
                          );
                          if (context.mounted) Navigator.pop(context);
                        } finally {
                          if (context.mounted) {
                            setState(() => _submitting = false);
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: VillageTheme.positive,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Assignment',
                        style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Chores Tab ──

class _ChoresTab extends StatelessWidget {
  final AsyncValue<List<Chore>> choresAsync;
  final WidgetRef ref;
  final String? userId;
  final bool isParent;
  const _ChoresTab({required this.choresAsync, required this.ref, this.userId, required this.isParent});

  @override
  Widget build(BuildContext context) {
    return choresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (chores) {
        if (chores.isEmpty) {
          return EmptyState(
            icon: Icons.cleaning_services_rounded,
            title: 'No chores yet',
            subtitle: isParent ? 'Tap + to create one' : 'Ask a parent to create chores',
          );
        }
        final topLevel = chores.where((c) => c.parentChoreId == null).toList();
        final rows = <Widget>[];
        for (final parent in topLevel) {
          final children =
              chores.where((c) => c.parentChoreId == parent.id).toList();
          final doneCount = children.where((c) => c.completedAt != null).length;
          rows.add(_choreTile(context, parent,
              isContainer: parent.isProject || parent.hasChildren,
              childCount: children.length,
              doneCount: doneCount));
          for (final child in children) {
            rows.add(_choreTile(context, child, isChild: true));
          }
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(choresListProvider.future),
          child: ListView(children: rows),
        );
      },
    );
  }

  Widget _choreTile(
    BuildContext context,
    Chore chore, {
    bool isContainer = false,
    bool isChild = false,
    int childCount = 0,
    int doneCount = 0,
  }) {
    final canManage = ref.read(authProvider).canManage;

    // Project/container chore: groups subtasks, not itself assignable.
    if (isContainer) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: context.palette.positive.withValues(alpha: 0.15),
          child: Icon(Icons.folder_outlined,
              color: context.palette.positive),
        ),
        title: Text(chore.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            childCount == 0 ? 'No tasks yet' : '$doneCount of $childCount done'),
        onTap: () => context.push('/chores/projects/${chore.id}'),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.only(left: isChild ? 36 : 16, right: 16),
      leading: CircleAvatar(
        backgroundColor: difficultyColorFilled(chore.difficulty),
        child: Text('${chore.pointValue}',
            style: const TextStyle(fontSize: 12, color: Colors.white)),
      ),
      title: Text(chore.name),
      subtitle: Text(
          '${chore.recurrence} · ${chore.difficulty}${chore.requiresApproval ? ' · Needs approval' : ''}'),
      trailing: PopupMenuButton<String>(
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'assign', child: Text('Assign')),
        ],
        onSelected: (action) {
          if (action == 'assign') {
            _showAssignDialog(context, chore.id);
          }
        },
      ),
      onTap: canManage ? () => _showEditChoreDialog(context, chore) : null,
    );
  }

  void _showAssignDialog(BuildContext context, String choreId) {
    final familyState = ref.read(familyProvider);
    final members = familyState.family?.members ?? [];

    // If family isn't loaded yet or has no members, show a simple state
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No family members loaded. Visit Hub to load your family.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Pre-select first member
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
                        color: context.palette.positive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.assignment_rounded,
                          color: context.palette.positive, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text('Assign Chore',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<MemberInfo>(
                  value: selectedMember,
                  decoration: InputDecoration(
                    labelText: 'Assign to',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: context.palette.surfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: members
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                Text(
                                  '${m.pointsBalance} ${ref.read(familyProvider).family?.currencyName ?? 'pts'}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedMember = v),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 1)),
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
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      filled: true,
                      fillColor: context.palette.surfaceBase,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    child: Text(
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (selectedMember == null) return;
                    final dueDate =
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                    await ref.read(choresServiceProvider).assignChore(
                          choreId,
                          selectedMember!.id,
                          dueDate,
                        );
                    ref.invalidate(assignmentsListProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: VillageTheme.positive,
                  ),
                  child: const Text('Assign',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditChoreDialog(BuildContext context, Chore chore) {
    final nameCtrl = TextEditingController(text: chore.name);
    final descCtrl = TextEditingController(text: chore.description ?? '');
    final pointCtrl = TextEditingController(text: '${chore.pointValue}');
    String recurrence = chore.recurrence;
    String difficulty = chore.difficulty;
    bool requiresApproval = chore.requiresApproval;
    bool requiresPhoto = chore.requiresPhoto;

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
                        color: context.palette.positive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.edit_outlined,
                          color: context.palette.positive, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text('Edit Chore',
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
                    fillColor: context.palette.surfaceBase,
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
                    fillColor: context.palette.surfaceBase,
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
                    fillColor: context.palette.surfaceBase,
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
                    fillColor: context.palette.surfaceBase,
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
                    fillColor: context.palette.surfaceBase,
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
                  activeColor: context.palette.positive,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Requires photo'),
                  value: requiresPhoto,
                  onChanged: (v) => setState(() => requiresPhoto = v),
                  activeColor: context.palette.positive,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await ref.read(choresServiceProvider).updateChore(
                          chore.id,
                          name: nameCtrl.text,
                          description: descCtrl.text,
                          pointValue: int.tryParse(pointCtrl.text) ?? chore.pointValue,
                          recurrence: recurrence,
                          difficulty: difficulty,
                          requiresApproval: requiresApproval,
                          requiresPhoto: requiresPhoto,
                        );
                    ref.invalidate(choresListProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: VillageTheme.positive,
                  ),
                  child: const Text('Save Changes',
                      style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: ctx,
                      builder: (dctx) => AlertDialog(
                        title: const Text('Delete Chore'),
                        content: Text(
                            'Delete "${chore.name}"? This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dctx, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      try {
                        await ref
                            .read(choresServiceProvider)
                            .deleteChore(chore.id);
                        ref.invalidate(choresListProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } on DioException catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Failed to delete: ${e.message}'),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete Chore',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Assignments Tab ──

class _AssignmentsTab extends StatelessWidget {
  final AsyncValue<List<ChoreAssignment>> assignmentsAsync;
  final WidgetRef ref;
  const _AssignmentsTab({required this.assignmentsAsync, required this.ref});

  @override
  Widget build(BuildContext context) {
    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assignments) {
        if (assignments.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_rounded,
            title: 'No assignments yet',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(assignmentsListProvider.future),
          child: ListView.builder(
            itemCount: assignments.length,
            itemBuilder: (ctx, i) {
              final a = assignments[i];
              final isPending = a.status == 'Pending';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPending ? Colors.orange : Colors.green,
                  child: Text('${a.chorePointValue}',
                      style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
                title: Text(a.choreName),
                subtitle: Text(
                    'Assigned to: ${a.assignedToName}\n${a.status}${a.completion != null ? ' · ${a.completion!.approvalStatus}' : ''}'),
                trailing: isPending
                    ? IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () async {
                          try {
                            await ref
                                .read(choresServiceProvider)
                                .completeChore(a.id);
                            ref.invalidate(assignmentsListProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Chore completed! ✓')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              final is409 = e is DioException && e.response?.statusCode == 409;
                              // 409 = already completed (double-tap or stale UI) — just refresh
                              ref.invalidate(assignmentsListProvider);
                              if (!is409) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error completing chore: $e')),
                                );
                              }
                            }
                          }
                        },
                      )
                    : Icon(a.completion?.approvalStatus == 'Approved'
                        ? Icons.check_circle
                        : Icons.pending),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Approvals Tab ──

class _ApprovalsTab extends StatelessWidget {
  final AsyncValue<List<ChoreAssignment>> assignmentsAsync;
  final WidgetRef ref;

  const _ApprovalsTab({required this.assignmentsAsync, required this.ref});

  @override
  Widget build(BuildContext context) {
    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assignments) {
        final pending = assignments
            .where((a) =>
                a.completion != null && a.completion!.approvalStatus == 'Pending')
            .toList();
        if (pending.isEmpty) {
          return const EmptyState(
            icon: Icons.verified_outlined,
            title: 'No pending approvals',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(assignmentsListProvider.future),
          child: ListView.builder(
            itemCount: pending.length,
            itemBuilder: (ctx, i) {
              final a = pending[i];
              final c = a.completion!;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text('${a.chorePointValue}',
                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  title: Text(a.choreName),
                  subtitle:
                      Text('Completed by: ${c.completedByName ?? 'someone'}\n${c.note ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed: () async {
                          try {
                            await ref
                                .read(choresServiceProvider)
                                .approveCompletion(c.id, true);
                            ref.invalidate(assignmentsListProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Completion approved ✓')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              final msg = e is DioException && e.response?.statusCode == 403
                                  ? 'Only a parent or caregiver can approve chores.'
                                  : 'Error approving: $e';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () async {
                          try {
                            await ref
                                .read(choresServiceProvider)
                                .approveCompletion(c.id, false);
                            ref.invalidate(assignmentsListProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Completion rejected')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Error rejecting: $e')),
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
