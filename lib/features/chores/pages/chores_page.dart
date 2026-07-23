import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/features/chores/chores_service.dart';

class ChoresPage extends ConsumerWidget {
  const ChoresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choresAsync = ref.watch(choresListProvider);
    final assignmentsAsync = ref.watch(assignmentsListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chores'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateChoreDialog(context, ref),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chores'),
              Tab(text: 'Assignments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ChoresTab(choresAsync: choresAsync, ref: ref),
            _AssignmentsTab(assignmentsAsync: assignmentsAsync, ref: ref),
          ],
        ),
      ),
    );
  }

  void _showCreateChoreDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointCtrl = TextEditingController(text: '10');
    String recurrence = 'Once';
    String difficulty = 'Easy';
    bool requiresApproval = true;
    bool requiresPhoto = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Chore'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Chore name'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                TextField(
                  controller: pointCtrl,
                  decoration: const InputDecoration(labelText: 'Point value'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: recurrence,
                  decoration: const InputDecoration(labelText: 'Recurrence'),
                  items: ['Once', 'Daily', 'Weekly', 'Monthly']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => recurrence = v!),
                ),
                DropdownButtonFormField<String>(
                  value: difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: ['Easy', 'Medium', 'Hard']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => difficulty = v!),
                ),
                SwitchListTile(
                  title: const Text('Requires approval'),
                  value: requiresApproval,
                  onChanged: (v) => setState(() => requiresApproval = v),
                ),
                SwitchListTile(
                  title: const Text('Requires photo'),
                  value: requiresPhoto,
                  onChanged: (v) => setState(() => requiresPhoto = v),
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
                ref.read(choresServiceProvider).createChore(
                      name: nameCtrl.text,
                      description: descCtrl.text,
                      pointValue: int.tryParse(pointCtrl.text) ?? 10,
                      recurrence: recurrence,
                      difficulty: difficulty,
                      requiresApproval: requiresApproval,
                      requiresPhoto: requiresPhoto,
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

class _ChoresTab extends StatelessWidget {
  final AsyncValue<List<Chore>> choresAsync;
  final WidgetRef ref;
  const _ChoresTab({required this.choresAsync, required this.ref});

  @override
  Widget build(BuildContext context) {
    return choresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (chores) {
        if (chores.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cleaning_services, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No chores yet. Tap + to create one.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
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
              );
            },
          ),
        );
      },
    );
  }

  void _showAssignDialog(BuildContext context, String choreId) {
    final memberCtrl = TextEditingController();
    final dueCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Chore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: memberCtrl,
              decoration: const InputDecoration(labelText: 'Member ID'),
            ),
            TextField(
              controller: dueCtrl,
              decoration: const InputDecoration(labelText: 'Due date (ISO)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(choresServiceProvider).assignChore(
                    choreId,
                    memberCtrl.text,
                    dueCtrl.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Assign'),
          ),
        ],
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
          return const Center(child: Text('No assignments yet.'));
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
                        onPressed: () {
                          ref.read(choresServiceProvider).completeChore(a.id);
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
