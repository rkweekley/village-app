import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/auth/auth_service.dart';
import 'package:village_app/core/auth/models.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  DateTime? _birthDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final userInfo = ref.read(authProvider).userInfo;
    _nameCtrl = TextEditingController(text: userInfo?.displayName ?? '');
    _emailCtrl = TextEditingController(text: userInfo?.email ?? '');
    if (userInfo?.birthDate != null) {
      _birthDate = DateTime.tryParse(userInfo!.birthDate!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and email are required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentUser = ref.read(authProvider).userInfo;
    if (currentUser == null) return;

    // Only send fields that actually changed
    final displayName = name != currentUser.displayName ? name : null;
    final emailParam = email != currentUser.email ? email : null;
    String? birthDateParam;
    if (_birthDate != null) {
      final bd = _birthDate!;
      final iso =
          '${bd.year.toString().padLeft(4, '0')}-${bd.month.toString().padLeft(2, '0')}-${bd.day.toString().padLeft(2, '0')}';
      if (iso != currentUser.birthDate) birthDateParam = iso;
    } else if (currentUser.birthDate != null) {
      birthDateParam = null; // clearing the date not supported by API — send current value unchanged
    }

    if (displayName == null && emailParam == null && birthDateParam == null) {
      // Nothing changed
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _submitting = true);
    try {
      final updated = await ref.read(authServiceProvider).updateProfile(
            displayName: displayName,
            email: emailParam,
            birthDate: birthDateParam,
          );
      ref.read(authProvider.notifier).updateUserInfo(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now.subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select birth date',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(authProvider).userInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _save,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VillageTheme.primary,
                    ),
                  )
                : const Text('Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar placeholder
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: VillageTheme.primary.withValues(alpha: 0.12),
              child: Text(
                (userInfo?.displayName ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: VillageTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              userInfo?.role ?? '',
              style: TextStyle(
                fontSize: 14,
                color: VillageTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Display Name
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Display Name',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: VillageTheme.surfaceBase,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Email
          TextField(
            controller: _emailCtrl,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: VillageTheme.surfaceBase,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Birth Date
          InkWell(
            onTap: _pickBirthDate,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Birth Date',
                prefixIcon: const Icon(Icons.cake_outlined),
                filled: true,
                fillColor: VillageTheme.surfaceBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              child: Text(
                _birthDate != null
                    ? '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}'
                    : 'Not set',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      _birthDate != null ? null : VillageTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Points (read-only)
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Points Balance',
              prefixIcon: const Icon(Icons.stars_rounded),
              filled: true,
              fillColor: VillageTheme.surfaceBase,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            child: Text(
              '${userInfo?.pointsBalance ?? 0} pts',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),

          // Save button (bottom)
          FilledButton(
            onPressed: _submitting ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: VillageTheme.primary,
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
                : const Text('Save Changes',
                    style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
