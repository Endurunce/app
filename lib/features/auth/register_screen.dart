import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/endurance_logo.dart';
import 'auth_provider.dart';
import 'login_screen.dart' show _ErrorBanner;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final ok = await ref.read(authProvider.notifier)
        .register(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) context.go('/intake');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),
              const Center(child: EnduranceLogo(subtitle: 'Maak je account aan en start je plan')),
              const SizedBox(height: 48),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: AppColors.onBg),
                      decoration: const InputDecoration(
                        labelText: 'E-mailadres',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      onSubmitted: (_) => _register(),
                      style: const TextStyle(color: AppColors.onBg),
                      decoration: InputDecoration(
                        labelText: 'Wachtwoord (min. 8 tekens)',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),

                    if (auth.error != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(auth.error!),
                    ],

                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: auth.loading ? null : _register,
                      child: auth.loading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Account aanmaken'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Al een account?', style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Inloggen'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
