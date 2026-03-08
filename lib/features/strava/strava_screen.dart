import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import 'strava_provider.dart';

class StravaScreen extends ConsumerStatefulWidget {
  const StravaScreen({super.key});

  @override
  ConsumerState<StravaScreen> createState() => _StravaScreenState();
}

class _StravaScreenState extends ConsumerState<StravaScreen> {
  // Setup flow step: 1 = credentials, 2 = authorize, 3 = paste code
  int _setupStep = 1;

  final _clientIdCtrl     = TextEditingController();
  final _clientSecretCtrl = TextEditingController();
  final _codeCtrl         = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(stravaProvider.notifier).checkStatus());
  }

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _clientSecretCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _openOAuth() {
    final clientId = _clientIdCtrl.text.trim();
    if (clientId.isEmpty) return;
    ref.read(stravaProvider.notifier).openStravaOAuth(clientId);
    setState(() => _setupStep = 3);
  }

  Future<void> _connect() async {
    await ref.read(stravaProvider.notifier).connectWithCode(
      clientId:     _clientIdCtrl.text.trim(),
      clientSecret: _clientSecretCtrl.text.trim(),
      code:         _codeCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stravaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Strava')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.connecting
              ? const _ConnectingState()
              : state.connected
                  ? _ConnectedView(state: state)
                  : _SetupFlow(
                      step:             _setupStep,
                      clientIdCtrl:     _clientIdCtrl,
                      clientSecretCtrl: _clientSecretCtrl,
                      codeCtrl:         _codeCtrl,
                      error:            state.error,
                      onNext: () {
                        if (_setupStep == 1) {
                          if (_clientIdCtrl.text.trim().isEmpty ||
                              _clientSecretCtrl.text.trim().isEmpty) return;
                          setState(() => _setupStep = 2);
                        } else if (_setupStep == 2) {
                          _openOAuth();
                        } else {
                          _connect();
                        }
                      },
                      onBack: _setupStep > 1
                          ? () => setState(() => _setupStep--)
                          : null,
                    ),
    );
  }
}

// ── Setup flow ─────────────────────────────────────────────────────────────────

class _SetupFlow extends StatelessWidget {
  final int step;
  final TextEditingController clientIdCtrl;
  final TextEditingController clientSecretCtrl;
  final TextEditingController codeCtrl;
  final String? error;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const _SetupFlow({
    required this.step,
    required this.clientIdCtrl,
    required this.clientSecretCtrl,
    required this.codeCtrl,
    required this.error,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Step indicator
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _StepIndicator(currentStep: step, steps: const ['Gegevens', 'Autoriseren', 'Code plakken']),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: switch (step) {
              1 => _StepCredentials(
                  clientIdCtrl:     clientIdCtrl,
                  clientSecretCtrl: clientSecretCtrl,
                ),
              2 => const _StepAuthorize(),
              3 => _StepPasteCode(codeCtrl: codeCtrl),
              _ => const SizedBox.shrink(),
            },
          ),
        ),

        if (error != null)
          Container(
            width: double.infinity,
            color: AppColors.errorDim,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center),
          ),

        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                FilledButton.icon(
                  onPressed: onNext,
                  icon: Icon(
                    step == 2
                        ? Icons.open_in_browser
                        : step == 3
                            ? Icons.link
                            : Icons.arrow_forward,
                    size: 18,
                  ),
                  label: Text(
                    step == 1
                        ? 'Volgende'
                        : step == 2
                            ? 'Open Strava'
                            : 'Verbinden',
                  ),
                ),
                if (onBack != null) ...[
                  const SizedBox(height: 8),
                  TextButton(onPressed: onBack, child: const Text('Terug')),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive   = i + 1 == currentStep;
        final isComplete = i + 1 < currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < steps.length - 1 ? 8 : 0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isComplete || isActive ? AppColors.brand : AppColors.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? AppColors.brand : AppColors.muted,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _StepCredentials extends StatelessWidget {
  final TextEditingController clientIdCtrl;
  final TextEditingController clientSecretCtrl;
  const _StepCredentials({required this.clientIdCtrl, required this.clientSecretCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.brand.withOpacity(.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: Text('🔑', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 16),
        Text('Strava koppelen',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Maak een Strava API-app aan op strava.com/settings/api en vul je gegevens in.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Instructies:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onBg)),
              const SizedBox(height: 8),
              ...[
                '1. Ga naar strava.com/settings/api',
                '2. Maak een nieuwe applicatie aan',
                '3. Zet "Authorization Callback Domain" op: localhost',
                '4. Kopieer Client ID en Client Secret hieronder',
              ].map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.onSurface, height: 1.5)),
              )),
            ],
          ),
        ),

        const SizedBox(height: 20),
        TextField(
          controller: clientIdCtrl,
          style: const TextStyle(color: AppColors.onBg),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Client ID',
            hintText: '12345',
            prefixIcon: Icon(Icons.tag, size: 18),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: clientSecretCtrl,
          style: const TextStyle(color: AppColors.onBg),
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Client Secret',
            hintText: '••••••••••••••••',
            prefixIcon: Icon(Icons.lock_outline, size: 18),
          ),
        ),
      ],
    );
  }
}

class _StepAuthorize extends StatelessWidget {
  const _StepAuthorize();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.brand.withOpacity(.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: Text('🌐', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 16),
        Text('Autoriseer in Strava',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Klik op "Open Strava" om je browser te openen. Log in en geef toestemming. Kopieer daarna de code uit de URL.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hoe de code vinden:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onBg)),
              const SizedBox(height: 8),
              ...[
                '1. De browser opent de Strava-pagina',
                '2. Klik op "Authorize"',
                '3. Je wordt omgeleid naar localhost (pagina kan fout geven)',
                '4. Kopieer de "code=..." waarde uit de URL',
              ].map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.onSurface, height: 1.5)),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepPasteCode extends StatelessWidget {
  final TextEditingController codeCtrl;
  const _StepPasteCode({required this.codeCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.easy.withOpacity(.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: Text('📋', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 16),
        Text('Plak de autorisatiecode',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Plak de code die je uit de URL hebt gekopieerd na het autoriseren bij Strava.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: codeCtrl,
          style: const TextStyle(color: AppColors.onBg, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            labelText: 'Autorisatiecode',
            hintText: 'abc123def456...',
            prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
          ),
        ),
      ],
    );
  }
}

// ── Connecting state ───────────────────────────────────────────────────────────

class _ConnectingState extends StatelessWidget {
  const _ConnectingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Verbinden met Strava...',
              style: TextStyle(color: AppColors.onSurface, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Connected view ─────────────────────────────────────────────────────────────

class _ConnectedView extends ConsumerWidget {
  final StravaState state;
  const _ConnectedView({required this.state});

  static const _typeEmoji = {
    'Run':      '🏃',
    'TrailRun': '🥾',
    'Hike':     '🥾',
    'Walk':     '🚶',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Athlete card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(children: [
            if (state.avatarUrl != null)
              ClipOval(
                child: Image.network(
                  state.avatarUrl!,
                  width: 52, height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _AvatarPlaceholder(),
                ),
              )
            else
              const _AvatarPlaceholder(),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.displayName ?? 'Strava-atleet',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.easy, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Verbonden',
                      style: TextStyle(fontSize: 12, color: AppColors.easy, fontWeight: FontWeight.w600)),
                ]),
              ],
            )),
            const Text('🏅', style: TextStyle(fontSize: 28)),
          ]),
        ),

        const SizedBox(height: 20),

        if (state.activities.isEmpty) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('🏃', style: TextStyle(fontSize: 40)),
                SizedBox(height: 12),
                Text('Geen activiteiten gevonden',
                    style: TextStyle(color: AppColors.onSurface, fontSize: 14)),
              ]),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Activiteiten laden'),
            onPressed: () => ref.read(stravaProvider.notifier).loadActivities(),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${state.activities.length} ACTIVITEITEN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
            ),
          ),
          ...state.activities.map((a) => _ActivityCard(activity: a, typeEmoji: _typeEmoji)),
        ],
      ],
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        shape: BoxShape.circle,
      ),
      child: const Center(child: Icon(Icons.person_outline, color: AppColors.muted, size: 28)),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final StravaActivity activity;
  final Map<String, String> typeEmoji;
  const _ActivityCard({required this.activity, required this.typeEmoji});

  @override
  Widget build(BuildContext context) {
    final emoji = typeEmoji[activity.type] ?? '🏃';
    final date  = activity.startDate;
    final dateStr = '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(dateStr,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${activity.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppColors.brand)),
            const SizedBox(height: 2),
            Text(activity.durationFormatted,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ]),
      ),
    );
  }
}
