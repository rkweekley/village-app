import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/family/family_provider.dart';
import 'package:village_app/features/family/family_service.dart';
import 'package:village_app/features/family/models.dart';

class FamilySetupPage extends ConsumerStatefulWidget {
  const FamilySetupPage({super.key});

  @override
  ConsumerState<FamilySetupPage> createState() => _FamilySetupPageState();
}

enum SetupStep { choose, create, join }

class _FamilySetupPageState extends ConsumerState<FamilySetupPage> {
  SetupStep _step = SetupStep.choose;

  // Create form
  final _createNameCtrl = TextEditingController();
  final _createCurrencyCtrl = TextEditingController(text: 'Points');
  bool _isCreating = false;

  // Join form
  final _joinCodeCtrl = TextEditingController();
  InviteCodeLookup? _lookedUpFamily;
  bool _isLookingUp = false;
  bool _isJoining = false;
  String? _lookupError;

  // Tracks whether setup was completed (navigated away to hub).
  // If false on dispose, the orphaned skeleton family will be cleaned up.
  bool _setupCompleted = false;

  @override
  void dispose() {
    _createNameCtrl.dispose();
    _createCurrencyCtrl.dispose();
    _joinCodeCtrl.dispose();
    // Cleanup of orphaned family skeleton not yet implemented — requires API endpoint
    super.dispose();
  }

  Future<void> _createFamily() async {
    final name = _createNameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      // The registration already created a family skeleton;
      // we just update its name via the PATCH endpoint.
      await ref.read(familyProvider.notifier).updateFamily(
            name: name,
            currencyName: _createCurrencyCtrl.text.trim(),
          );
      _setupCompleted = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family created!')),
        );
        context.go('/hub');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create family: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _lookupCode() async {
    final code = _joinCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isLookingUp = true;
      _lookupError = null;
      _lookedUpFamily = null;
    });

    try {
      final service = ref.read(familyServiceProvider);
      final result = await service.lookupInviteCode(code);
      if (result != null) {
        setState(() => _lookedUpFamily = result);
      } else {
        setState(() => _lookupError = 'Invite code not found.');
      }
    } catch (e) {
      setState(() => _lookupError = 'Lookup failed: $e');
    } finally {
      setState(() => _isLookingUp = false);
    }
  }

  Future<void> _joinFamily() async {
    final code = _joinCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isJoining = true);
    try {
      // Joining an existing family post-registration is not yet supported.
      // Users must join via the registration flow with an invite code.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
            'Joining a family after registration is coming soon. '
            'For now, register with the invite code to join.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Setup'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case SetupStep.choose:
        return _buildChooseStep();
      case SetupStep.create:
        return _buildCreateStep();
      case SetupStep.join:
        return _buildJoinStep();
    }
  }

  Widget _buildChooseStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.family_restroom,
          size: 80,
          color: VillageTheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to Village!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: VillageTheme.primary,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Set up your family to get started.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        FilledButton.icon(
          onPressed: () => setState(() => _step = SetupStep.create),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add_home),
          label: const Text('Create a Family'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => setState(() => _step = SetupStep.join),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.meeting_room),
          label: const Text('Join Existing Family'),
        ),
      ],
    );
  }

  Widget _buildCreateStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Create Your Family',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _createNameCtrl,
            decoration: InputDecoration(
              labelText: 'Family Name',
              hintText: 'e.g. The Smiths',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              prefixIcon: const Icon(Icons.badge),
              filled: true,
              fillColor: VillageTheme.surfaceBase,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _createCurrencyCtrl,
            decoration: InputDecoration(
              labelText: 'Currency Name',
              hintText: 'Points',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              prefixIcon: const Icon(Icons.monetization_on),
              filled: true,
              fillColor: VillageTheme.surfaceBase,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isCreating ? null : _createFamily,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Family'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _step = SetupStep.choose;
              _createNameCtrl.clear();
            }),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Join a Family',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the invite code shared by your family.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _joinCodeCtrl,
            decoration: InputDecoration(
              labelText: 'Invite Code',
              hintText: 'e.g. VILLAGE1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              prefixIcon: const Icon(Icons.vpn_key),
              filled: true,
              fillColor: VillageTheme.surfaceBase,
              suffixIcon: _joinCodeCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _joinCodeCtrl.clear();
                        setState(() {
                          _lookedUpFamily = null;
                          _lookupError = null;
                        });
                      },
                    )
                  : null,
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {
              _lookedUpFamily = null;
              _lookupError = null;
            }),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isLookingUp ? null : _lookupCode,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isLookingUp
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: const Text('Look Up'),
          ),
          if (_lookupError != null) ...[
            const SizedBox(height: 12),
            Text(
              _lookupError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_lookedUpFamily != null) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              color: VillageTheme.surfaceCard,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lookedUpFamily!.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_lookedUpFamily!.memberCount} member${_lookedUpFamily!.memberCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isJoining ? null : _joinFamily,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isJoining
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Join Family'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _step = SetupStep.choose;
              _joinCodeCtrl.clear();
              _lookedUpFamily = null;
              _lookupError = null;
            }),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
