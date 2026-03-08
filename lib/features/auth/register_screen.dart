import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/endurance_logo.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Fase 1: account
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  // Fase 2: persoonlijk
  final _nameCtrl = TextEditingController();
  final _ageCtrl  = TextEditingController();
  String? _gender;

  int _phase = 1; // 1 = account, 2 = persoonlijk

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _registerAccount() async {
    final ok = await ref.read(authProvider.notifier)
        .register(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) {
      setState(() => _phase = 2);
    }
  }

  void _submitPersonal() {
    final age = int.tryParse(_ageCtrl.text.trim());
    if (_nameCtrl.text.trim().isEmpty || age == null || _gender == null) return;

    ref.read(authProvider.notifier).setPersonalInfo(
      name:   _nameCtrl.text.trim(),
      age:    age,
      gender: _gender!,
    );
    context.go('/intake');
  }

  bool get _phase2Valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      int.tryParse(_ageCtrl.text.trim()) != null &&
      _gender != null;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: _phase == 1
              ? _Phase1(
                  key: const ValueKey(1),
                  emailCtrl:    _emailCtrl,
                  passwordCtrl: _passwordCtrl,
                  obscure:      _obscure,
                  loading:      auth.loading,
                  error:        auth.error,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  onSubmit:     _registerAccount,
                )
              : _Phase2(
                  key: const ValueKey(2),
                  nameCtrl: _nameCtrl,
                  ageCtrl:  _ageCtrl,
                  gender:   _gender,
                  valid:    _phase2Valid,
                  onGenderSelect: (v) => setState(() => _gender = v),
                  onNameChanged:  () => setState(() {}),
                  onAgeChanged:   () => setState(() {}),
                  onSubmit:       _submitPersonal,
                ),
        ),
      ),
    );
  }
}

// ── Fase 1: account aanmaken ──────────────────────────────────────────────────

class _Phase1 extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final bool loading;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _Phase1({
    super.key,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.loading,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                  controller: emailCtrl,
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
                  controller: passwordCtrl,
                  obscureText: obscure,
                  onSubmitted: (_) => onSubmit(),
                  style: const TextStyle(color: AppColors.onBg),
                  decoration: InputDecoration(
                    labelText: 'Wachtwoord (min. 8 tekens)',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: onToggleObscure,
                    ),
                  ),
                ),

                if (error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(error!),
                ],

                const SizedBox(height: 20),
                FilledButton(
                  onPressed: loading ? null : onSubmit,
                  child: loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Volgende'),
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
    );
  }
}

// ── Fase 2: persoonlijke gegevens ─────────────────────────────────────────────

class _Phase2 extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController ageCtrl;
  final String? gender;
  final bool valid;
  final ValueChanged<String> onGenderSelect;
  final VoidCallback onNameChanged;
  final VoidCallback onAgeChanged;
  final VoidCallback onSubmit;

  const _Phase2({
    super.key,
    required this.nameCtrl,
    required this.ageCtrl,
    required this.gender,
    required this.valid,
    required this.onGenderSelect,
    required this.onNameChanged,
    required this.onAgeChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 56),
          const Center(
            child: Text('👤', style: TextStyle(fontSize: 52)),
          ),
          const SizedBox(height: 16),
          Text(
            'Even kennismaken',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We gebruiken dit om je trainingsplan te personaliseren.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

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
                  controller: nameCtrl,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: AppColors.onBg),
                  decoration: const InputDecoration(
                    labelText: 'Voornaam',
                    hintText: 'Bijv. Sanne',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  onChanged: (_) => onNameChanged(),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.onBg),
                  decoration: const InputDecoration(
                    labelText: 'Leeftijd',
                    hintText: '28',
                    prefixIcon: Icon(Icons.cake_outlined, size: 20),
                  ),
                  onChanged: (_) => onAgeChanged(),
                ),
                const SizedBox(height: 20),

                Text('Geslacht',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1)),
                const SizedBox(height: 10),
                _GenderChips(selected: gender, onSelect: onGenderSelect),

                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: valid ? onSubmit : null,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Plan opmaken'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _GenderChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _GenderChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const options = [('male', 'Man'), ('female', 'Vrouw'), ('other', 'Anders')];
    return Row(
      children: options.map((o) {
        final isSelected = selected == o.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(o.$2),
            selected: isSelected,
            onSelected: (_) => onSelect(o.$1),
          ),
        );
      }).toList(),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: .4)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13))),
      ]),
    );
  }
}
