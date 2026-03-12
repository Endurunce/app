import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/utils/age.dart';
import '../../shared/widgets/endurance_logo.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/gender_chips.dart';
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
  DateTime? _dateOfBirth;
  String? _gender;

  int _phase = 1; // 1 = account, 2 = persoonlijk

  // Form keys
  final _phase1FormKey = GlobalKey<FormState>();
  bool _phase1Submitted = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Voer een e-mailadres in.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Voer een geldig e-mailadres in.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Voer een wachtwoord in.';
    if (value.length < 8) return 'Wachtwoord moet minimaal 8 tekens bevatten.';
    return null;
  }

  Future<void> _registerAccount() async {
    setState(() => _phase1Submitted = true);
    if (!_phase1FormKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier)
        .register(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) {
      setState(() => _phase = 2);
    }
  }

  bool get _isUnderSixteen {
    if (_dateOfBirth == null) return false;
    return calculateAge(_dateOfBirth!) < 16;
  }

  void _submitPersonal() {
    if (_nameCtrl.text.trim().isEmpty || _dateOfBirth == null || _gender == null) return;
    if (_isUnderSixteen) return;

    ref.read(authProvider.notifier).setPersonalInfo(
      name:        _nameCtrl.text.trim(),
      dateOfBirth: _dateOfBirth!,
      gender:      _gender!,
    );
    context.go('/intake', extra: true);
  }

  bool get _phase2Valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _dateOfBirth != null &&
      !_isUnderSixteen &&
      _gender != null;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                  formKey:      _phase1FormKey,
                  submitted:    _phase1Submitted,
                  emailCtrl:    _emailCtrl,
                  passwordCtrl: _passwordCtrl,
                  obscure:      _obscure,
                  loading:      auth.loading,
                  error:        auth.error,
                  validateEmail:    _validateEmail,
                  validatePassword: _validatePassword,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  onSubmit:     _registerAccount,
                )
              : _Phase2(
                  key:          const ValueKey(2),
                  nameCtrl:     _nameCtrl,
                  dateOfBirth:  _dateOfBirth,
                  isUnder16:    _isUnderSixteen,
                  gender:       _gender,
                  valid:        _phase2Valid,
                  onGenderSelect:    (v) => setState(() => _gender = v),
                  onNameChanged:     () => setState(() {}),
                  onDateOfBirthPick: (d) => setState(() => _dateOfBirth = d),
                  onSubmit:          _submitPersonal,
                ),
        ),
      ),
    );
  }
}

// ── Fase 1: account aanmaken ──────────────────────────────────────────────────

class _Phase1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool submitted;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final bool loading;
  final String? error;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _Phase1({
    super.key,
    required this.formKey,
    required this.submitted,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.loading,
    required this.error,
    required this.validateEmail,
    required this.validatePassword,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
            child: Form(
              key: formKey,
              autovalidateMode: submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppColors.onBg),
                    validator: validateEmail,
                    decoration: const InputDecoration(
                      labelText: 'E-mailadres',
                      prefixIcon: Icon(Icons.mail_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    onFieldSubmitted: (_) => onSubmit(),
                    validator: validatePassword,
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
                    ErrorBanner(error!),
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

// ── Fase 2: persoonlijke gegevens ─────────────────────────────────────────────

class _Phase2 extends StatelessWidget {
  final TextEditingController nameCtrl;
  final DateTime? dateOfBirth;
  final bool isUnder16;
  final String? gender;
  final bool valid;
  final ValueChanged<String> onGenderSelect;
  final VoidCallback onNameChanged;
  final ValueChanged<DateTime> onDateOfBirthPick;
  final VoidCallback onSubmit;

  const _Phase2({
    super.key,
    required this.nameCtrl,
    required this.dateOfBirth,
    required this.isUnder16,
    required this.gender,
    required this.valid,
    required this.onGenderSelect,
    required this.onNameChanged,
    required this.onDateOfBirthPick,
    required this.onSubmit,
  });

  String get _dobLabel {
    if (dateOfBirth == null) return 'Geboortedatum kiezen';
    return '${dateOfBirth!.day.toString().padLeft(2, '0')}-'
        '${dateOfBirth!.month.toString().padLeft(2, '0')}-'
        '${dateOfBirth!.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Selecteer je geboortedatum',
    );
    if (picked != null) onDateOfBirthPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
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

                // Geboortedatum picker (verplicht voor DPIA leeftijdsverificatie)
                GestureDetector(
                  onTap: () => _pickDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Geboortedatum',
                      prefixIcon: const Icon(Icons.cake_outlined, size: 20),
                      errorText: isUnder16
                          ? 'Je moet minimaal 16 jaar oud zijn om deze app te gebruiken.'
                          : null,
                    ),
                    child: Text(
                      _dobLabel,
                      style: TextStyle(
                        color: dateOfBirth == null ? AppColors.muted : AppColors.onBg,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text('Geslacht',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1)),
                const SizedBox(height: 10),
                GenderChips(selected: gender, onSelect: onGenderSelect),

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
    ),
      ),
    );
  }
}
