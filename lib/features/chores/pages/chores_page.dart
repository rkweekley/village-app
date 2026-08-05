import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/chores/chores_service.dart';
import 'package:village_app/features/family/family_provider.dart';
import 'package:village_app/features/family/models.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/widgets/empty_state.dart';
import 'package:village_app/shared/widgets/adaptive_sheet.dart';

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
    final tabCount = isParent ? 3 : 2;

    // Sync tab count if role changed (unlikely but safe)
    if (_tabController.length != tabCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _currentTab = _tabController.index);
        }
      });
    }

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
              onPressed: () {
                if (_currentTab == 0) {
                  _showCreateChoreDialog(context);
                } else if (_currentTab == 1) {
                  _showCreateAssignmentDialog(context);
                }
              },
              child: const Icon(Icons.add),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChoresTab(choresAsync: choresAsync, ref: ref, userId: userId),
          _AssignmentsTab(
              assignmentsAsync: assignmentsAsync, ref: ref),
          if (isParent)
            _ApprovalsTab(
                assignmentsAsync: assignmentsAsync, ref: ref),
        ],
      ),
    );
  }

  // ── Create Chore ──

  void _showCreateChoreDialog(BuildContext context) {
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
                  controller: nameCtrl,
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
                  controller: pointCtrl,
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
                  value: recurrence,
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
                  onChanged: (v) => setState(() => recurrence = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: difficulty,
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
                  onChanged: (v) => setState(() => difficulty = v!),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Requires approval'),
                  value: requiresApproval,
                  onChanged: (v) => setState(() => requiresApproval = v),
                  activeColor: VillageTheme.positive,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Requires photo'),
                  value: requiresPhoto,
                  onChanged: (v) => setState(() => requiresPhoto = v),
                  activeColor: VillageTheme.positive,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await ref.read(choresServiceProvider).createChore(
                          name: nameCtrl.text,
                          description: descCtrl.text,
                          pointValue: int.tryParse(pointCtrl.text) ?? 10,
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

  // ── Create Assignment ──

  void _showCreateAssignmentDialog(BuildContext context) {
    final familyState = ref.read(familyProvider);
    final members = familyState.family?.members ?? [];
    final choresData = ref.read(choresListProvider).asData?.value ?? [];

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
          content: Text('No chores exist yet. Create some chores first.'),
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
  final Future<void> Function(String choreId, String assignedToId, String dueDate)
      onAssign;

  const _CreateAssignmentSheet({
    required this.chores,
    required this.members,
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
                    color: VillageTheme.positive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_rounded,
                      color: VillageTheme.positive, size: 22),
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
                      fillColor: VillageTheme.surfaceBase,
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
                                    VillageTheme.positive.withValues(alpha: 0.15),
                                child: Text('${chore.pointValue}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: VillageTheme.positive)),
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
                                '${m.pointsBalance} pts',
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
                    fillColor: VillageTheme.surfaceBase,
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
  const _ChoresTab({required this.choresAsync, required this.ref, this.userId});

  @override
  Widget build(BuildContext context) {
    return choresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (chores) {
        if (chores.isEmpty) {
          return const EmptyState(
            icon: Icons.cleaning_services_rounded,
            title: 'No chores yet',
            subtitle: 'Tap + to create one',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(choresListProvider.future),
          child: ListView.builder(
            itemCount: chores.length,
            itemBuilder: (ctx, i) {
              final chore = chores[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _difficultyColor(chore.difficulty),
                  child: Text('${chore.pointValue}',
                      style: const TextStyle(fontSize: 12)),
                ),
                title: Text(chore.name),
                subtitle: Text(
                    '${chore.recurrence} · ${chore.difficulty}${chore.requiresApproval ? ' · Needs approval' : ''}'),
                trailing: PopupMenuButton(
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'assign', child: Text('Assign'))
                  ],
                  onSelected: (action) {
                    if (action == 'assign') {
                      _showAssignDialog(context, chore.id);
                    }
                  },
                ),
                onTap: chore.createdById != null && chore.createdById == userId
                    ? () => _showEditChoreDialog(context, chore)
                    : null,
              );
            },
          ),
        );
      },
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
                        color: VillageTheme.positive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_rounded,
                          color: VillageTheme.positive, size: 22),
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
                    fillColor: VillageTheme.surfaceBase,
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
                                  '${m.pointsBalance} pts',
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
                      fillColor: VillageTheme.surfaceBase,
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
                        color: VillageTheme.positive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          color: VillageTheme.positive, size: 22),
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
                  controller: pointCtrl,
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
                  value: recurrence,
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
                  onChanged: (v) => setState(() => recurrence = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: difficulty,
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
                  onChanged: (v) => setState(() => difficulty = v!),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Requires approval'),
                  value: requiresApproval,
                  onChanged: (v) => setState(() => requiresApproval = v),
                  activeColor: VillageTheme.positive,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Requires photo'),
                  value: requiresPhoto,
                  onChanged: (v) => setState(() => requiresPhoto = v),
                  activeColor: VillageTheme.positive,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
                    'Assigned to: ${a.assignedToName}\\n${a.status}${a.completion != null ? ' · ${a.completion!.approvalStatus}' : ''}'),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Error completing chore: $e')),
                              );
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
                      Text('Completed by: ${a.assignedToName}\\n${c.note ?? ''}'),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Error approving: $e')),
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
