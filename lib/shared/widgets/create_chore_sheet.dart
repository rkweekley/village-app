import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/chores/chores_service.dart';
import 'package:village_app/shared/widgets/adaptive_sheet.dart';

/// Shows the create-chore bottom sheet / dialog and returns when the sheet
/// is dismissed (after a successful create or manual close).
///
/// Call from any page that has access to a [WidgetRef]:
/// ```dart
/// showCreateChoreSheet(context, ref);
/// ```
Future<void> showCreateChoreSheet(BuildContext context, WidgetRef ref) {
  return showAdaptiveModalSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _CreateChoreSheet(ref: ref),
  );
}

// ── Internal widget ──

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
  bool _submitting = false;

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
                  child: Icon(Icons.cleaning_services_rounded,
                      color: context.palette.positive, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('New Chore',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),

            // Name
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

            // Description
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

            // Point value
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

            // Recurrence
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

            // Difficulty
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

            // Switches
            SwitchListTile(
              title: const Text('Requires approval'),
              value: _requiresApproval,
              onChanged: (v) => setState(() => _requiresApproval = v),
              activeColor: context.palette.positive,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Requires photo'),
              value: _requiresPhoto,
              onChanged: (v) => setState(() => _requiresPhoto = v),
              activeColor: context.palette.positive,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // Submit
            FilledButton(
              onPressed: _submitting ? null : _create,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: VillageTheme.positive,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Chore',
                      style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create chore: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}
