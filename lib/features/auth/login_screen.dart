import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/endurance_logo.dart';
import '../../shared/widgets/error_banner.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitted = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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

  Future<void> _login() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) context.go('/plan');
  }

  Future<void> _googleLogin() async {
    final ok = await ref.read(authProvider.notifier).loginWithGoogle();
    if (ok && mounted) context.go('/plan');
  }

  Future<void> _stravaLogin() async {
    final ok = await ref.read(authProvider.notifier).loginWithStrava();
    if (ok && mounted) context.go('/plan');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),
              const Center(child: EnduranceLogo(subtitle: 'Welkom terug')),
              const SizedBox(height: 48),

              // Form card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: AppColors.onBg),
                        validator: _validateEmail,
                        decoration: const InputDecoration(
                          labelText: 'E-mailadres',
                          prefixIcon: Icon(Icons.mail_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        onFieldSubmitted: (_) => _login(),
                        validator: _validatePassword,
                        style: const TextStyle(color: AppColors.onBg),
                        decoration: InputDecoration(
                          labelText: 'Wachtwoord',
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
                        ErrorBanner(auth.error!),
                      ],

                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: auth.loading ? null : _login,
                        child: auth.loading
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Inloggen'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Social login
              _Divider(label: 'of ga verder met'),
              const SizedBox(height: 16),

              _SocialButton(
                onPressed: auth.loading ? null : _googleLogin,
                icon: const _GoogleIcon(),
                label: 'Google',
              ),
              const SizedBox(height: 10),
              _SocialButton(
                onPressed: auth.loading ? null : _stravaLogin,
                icon: const Icon(Icons.directions_run, size: 20, color: Color(0xFFFC4C02)),
                label: 'Strava',
                accentColor: const Color(0xFFFC4C02),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Nog geen account?',
                      style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Registreren'),
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

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
      const Expanded(child: Divider()),
    ]);
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color? accentColor;
  const _SocialButton({required this.onPressed, required this.icon,
      required this.label, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accentColor?.withValues(alpha: .5) ?? AppColors.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text('Doorgaan met $label',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20, height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = size.width * 0.17;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.88), -1.57, 1.57, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.88), 0, 1.57, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.88), 1.57, 1.57, false, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.88), 3.14, 1.57, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
