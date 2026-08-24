import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/core/auth/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final String? inviteCode;

  const RegisterPage({super.key, this.inviteCode});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    if (widget.inviteCode != null && widget.inviteCode!.isNotEmpty) {
      _inviteCtrl.text = widget.inviteCode!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Age gate: block under-13 self-registration before calling the API.
    if (_birthDate != null && _ageInYears(_birthDate!) < 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You must be at least 13 to create an account. Ask a parent or guardian to create the family account and add you.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    ref.read(authProvider.notifier).clearError();

    try {
      await ref.read(authProvider.notifier).register(
            email: _emailCtrl.text.trim(),
            displayName: _nameCtrl.text.trim(),
            password: _passwordCtrl.text,
            inviteCode: _inviteCtrl.text.trim().isEmpty
                ? null
                : _inviteCtrl.text.trim(),
            birthDate: _birthDate != null ? _formatIso(_birthDate!) : null,
          );
      if (mounted) context.go('/hub');
    } catch (_) {
      // error handled in auth state
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _ageInYears(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _formatIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now.subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your birth date',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // Back
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Text(
                  'Join Village',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a new family or join an existing one',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Card
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceElevated,
                    borderRadius: BorderRadius.circular(VillageTheme.radiusXl),
                    border: Border.all(
                      color: context.palette.borderSubtle,
                      width: 0.5,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error
                        if (state.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.palette.danger
                                  .withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(VillageTheme.radiusSm),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    size: 18, color: context.palette.danger),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: context.palette.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Name
                        TextFormField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Your name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'Enter at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your email';
                            }
                            if (!v.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 8) {
                              return 'At least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Invite code
                        TextFormField(
                          controller: _inviteCtrl,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Family invite code (optional)',
                            prefixIcon: Icon(Icons.group_add_outlined),
                            helperText:
                                'Leave blank to create a new family',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Birth date (age gate)
                        InkWell(
                          onTap: _pickBirthDate,
                          borderRadius:
                              BorderRadius.circular(VillageTheme.radiusMd),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Birth date',
                              prefixIcon: Icon(Icons.cake_outlined),
                              helperText:
                                  'You must be 13 or older to create an account.',
                            ),
                            child: Text(
                              _birthDate != null
                                  ? '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}'
                                  : 'Select your birth date',
                              style: TextStyle(
                                fontSize: 16,
                                color: _birthDate != null
                                    ? null
                                    : context.palette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Register button
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _loading ? null : _handleRegister,
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Create account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.palette.textTertiary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.palette.primary,
                      ),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
