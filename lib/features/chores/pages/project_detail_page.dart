import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/core/widgets/empty_state.dart';
import 'package:village_app/features/chores/chores_service.dart';
import 'package:village_app/shared/widgets/adaptive_sheet.dart';

/// A project's detail view: shows its tasks, lets a parent add tasks inline,
/// and lets anyone check tasks off. The "project" is a top-level chore whose
/// children are its tasks.
class ProjectDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  final _taskCtrl = TextEditingController();
  final _taskFocus = FocusNode();
  bool _adding = false;

  @override
  void dispose() {
    _taskCtrl.dispose();
    _taskFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final choresAsync = ref.watch(choresListProvider);
    final isParent = ref.watch(authProvider).canManage;

    final projectName = choresAsync.maybeWhen(
      data: (chores) {
        for (final c in chores) {
          if (c.id == widget.projectId) return c.name;
        }
        return 'Project';
      },
      orElse: () => 'Project',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(projectName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isParent)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit project',
              onPressed: () => _showEditSheet(context, choresAsync),
            ),
          if (isParent)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete project',
              onPressed: () => _deleteProject(context),
            ),
        ],
      ),
      body: choresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (chores) {
          var found = false;
          for (final c in chores) {
            if (c.id == widget.projectId) {
              found = true;
              break;
            }
          }
          if (!found) {
            return const EmptyState(
              icon: Icons.folder_off_outlined,
              title: 'Project not found',
            );
          }

          final tasks =
              chores.where((c) => c.parentChoreId == widget.projectId).toList();
          final doneCount = tasks.where((t) => t.completedAt != null).length;

          return Column(
            children: [
              _progressHeader(done: doneCount, total: tasks.length),
              if (isParent) _buildAddTaskField(),
              Expanded(
                child: tasks.isEmpty
                    ? const EmptyState(
                        icon: Icons.checklist_rounded,
                        title: 'No tasks yet',
                        subtitle: 'Add a task to get started',
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(choresListProvider.future),
                        child: ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (ctx, i) => _taskTile(tasks[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _progressHeader({required int done, required int total}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VillageTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: VillageTheme.positive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.checklist_rounded, color: VillageTheme.positive),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0 ? 'No tasks yet' : '$done of $total done',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 6,
                    backgroundColor: VillageTheme.borderSubtle,
                    color: VillageTheme.positive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTaskField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _taskCtrl,
        focusNode: _taskFocus,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Add a task…',
          prefixIcon: const Icon(Icons.add_rounded),
          filled: true,
          fillColor: VillageTheme.surfaceBase,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _addTask(),
      ),
    );
  }

  Widget _taskTile(Chore task) {
    final done = task.completedAt != null;
    return ListTile(
      leading: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done ? VillageTheme.positive : VillageTheme.textTertiary,
      ),
      title: Text(
        task.name,
        style: TextStyle(
          decoration: done ? TextDecoration.lineThrough : null,
          color: done ? VillageTheme.textTertiary : null,
        ),
      ),
      onTap: () => _toggle(task),
    );
  }

  Future<void> _addTask() async {
    final name = _taskCtrl.text.trim();
    if (name.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      await ref.read(choresServiceProvider).createChore(
            name: name,
            parentChoreId: widget.projectId,
          );
      ref.invalidate(choresListProvider);
      _taskCtrl.clear();
      _taskFocus.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add task: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _toggle(Chore task) async {
    try {
      await ref.read(choresServiceProvider).toggleChoreComplete(task.id);
      ref.invalidate(choresListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteProject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text(
            'Delete this project and all of its tasks? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(choresServiceProvider).deleteChore(widget.projectId);
      ref.invalidate(choresListProvider);
      if (context.mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.message}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showEditSheet(BuildContext context, AsyncValue<List<Chore>> choresAsync) {
    Chore? project;
    for (final c in (choresAsync.asData?.value ?? const <Chore>[])) {
      if (c.id == widget.projectId) {
        project = c;
        break;
      }
    }
    if (project == null) return;
    final p = project;

    final nameCtrl = TextEditingController(text: p.name);
    final descCtrl = TextEditingController(text: p.description ?? '');

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                    const Text('Edit Project',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Project name',
                    prefixIcon: const Icon(Icons.folder_outlined),
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
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    try {
                      await ref.read(choresServiceProvider).updateChore(
                            p.id,
                            name: name,
                            description: descCtrl.text.trim(),
                            pointValue: p.pointValue,
                            recurrence: p.recurrence,
                            difficulty: p.difficulty,
                            requiresApproval: p.requiresApproval,
                            requiresPhoto: p.requiresPhoto,
                          );
                      ref.invalidate(choresListProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update: $e'),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    }
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
}
