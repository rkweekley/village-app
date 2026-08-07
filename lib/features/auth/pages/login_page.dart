import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/core/auth/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _redirectChecked = false;

  @override
  void initState() {
    super.initState();
    // Check URL hash for invite code — GoRouter hash routing is unreliable
    // on first load, so we read window.location directly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_redirectChecked) return;
      _redirectChecked = true;
      try {
        final hash = Uri.base.fragment;
        // Match #/register/CODE or #/register?code=CODE
        final registerMatch = RegExp(r'^/register/([A-Z0-9]+)').firstMatch(hash);
        final queryMatch = RegExp(r'^/register\?code=([A-Z0-9]+)').firstMatch(hash);
        final code = registerMatch?.group(1) ?? queryMatch?.group(1);
        if (code != null && code.isNotEmpty && mounted) {
          context.go('/register/$code');
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    ref.read(authProvider.notifier).clearError();

    try {
      await ref.read(authProvider.notifier).login(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (mounted) context.go('/hub');
    } catch (_) {
      // error handled in auth state
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: VillageTheme.surfaceBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),

                // ── Brand logo ──
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  width: 100,
                ),
                const SizedBox(height: 8),
                Text(
                  'It takes a village to raise a family',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: VillageTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 40),

                // ── Card ──
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: VillageTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(VillageTheme.radiusXl),
                    border: Border.all(
                      color: VillageTheme.borderSubtle,
                      width: 0.5,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome back',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: VillageTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to your family account',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: VillageTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error
                        if (state.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: VillageTheme.danger.withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(VillageTheme.radiusSm),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    size: 18, color: VillageTheme.danger),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: VillageTheme.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

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
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 28),

                        // Login button
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _loading ? null : _handleLogin,
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Sign in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Forgot password
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    style: TextButton.styleFrom(
                      foregroundColor: VillageTheme.textSecondary,
                    ),
                    child: const Text('Forgot password?'),
                  ),
                ),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: VillageTheme.textTertiary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      style: TextButton.styleFrom(
                        foregroundColor: VillageTheme.primary,
                      ),
                      child: const Text('Create one'),
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
