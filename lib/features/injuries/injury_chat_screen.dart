import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/chat/chat_form.dart';
import '../injury/injury_provider.dart';
import '../plan/plan_provider.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

/// True when at least one location is a single-sided body part.
bool _hasSidedLocation(Map<String, dynamic> answers) {
  const bothSides = {'lower_back'};
  final raw = answers['location'] as String? ?? '';
  final selected = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
  return selected.difference(bothSides).isNotEmpty;
}

/// Map pain type value → Dutch label.
String _painTypeLabel(String value) => switch (value) {
  'sharp'     => 'Stekend',
  'throbbing' => 'Kloppend',
  'stiff'     => 'Stijf',
  'burning'   => 'Brandend',
  'pulling'   => 'Trekkend',
  _           => value,
};

/// Map session type → Dutch label.
String _sessionLabel(String type) => switch (type) {
  'easy'     => 'Easy',
  'tempo'    => 'Tempo',
  'long'     => 'Lange duurloop',
  'interval' => 'Interval',
  'cross'    => 'Crosstraining',
  'hike'     => 'Hike',
  'race'     => 'Race',
  'rest'     => 'Rust',
  _          => type,
};

// ── Chat steps ─────────────────────────────────────────────────────────────────

final _steps = <ChatFormStep>[
  // Locatie
  ChatFormStep(
    id: 'location',
    question: 'Waar zit de pijn? Je kunt meerdere plekken kiezen.',
    inputType: ChatInputType.multiChips,
    options: [
      ChatOption(label: 'Knie',      value: 'knee',       emoji: '🦵'),
      ChatOption(label: 'Achilles',  value: 'achilles',   emoji: '🦶'),
      ChatOption(label: 'Scheenbeen',value: 'shin',       emoji: '🦴'),
      ChatOption(label: 'Heup',      value: 'hip',        emoji: '🫀'),
      ChatOption(label: 'Hamstring', value: 'hamstring',  emoji: '🏃'),
      ChatOption(label: 'Kuit',      value: 'calf',       emoji: '🦵'),
      ChatOption(label: 'Voet',      value: 'foot',       emoji: '🦶'),
      ChatOption(label: 'Enkel',     value: 'ankle',      emoji: '🦶'),
      ChatOption(label: 'Onderrug',  value: 'lower_back', emoji: '🔙'),
      ChatOption(label: 'Schouder',  value: 'shoulder',   emoji: '💪'),
      ChatOption(label: 'IT-band',   value: 'it_band',    emoji: '🦵'),
    ],
  ),

  // Kant (alleen bij enkelvoudige locaties)
  ChatFormStep(
    id: 'side',
    question: 'Aan welke kant?',
    inputType: ChatInputType.chips,
    showIf: _hasSidedLocation,
    options: [
      ChatOption(label: 'Links',  value: 'left',  emoji: '⬅️'),
      ChatOption(label: 'Rechts', value: 'right', emoji: '➡️'),
      ChatOption(label: 'Beide',  value: 'both',  emoji: '↔️'),
    ],
  ),

  // Ernst
  ChatFormStep(
    id: 'severity',
    question: 'Hoe erg is de pijn op een schaal van 1 (nauwelijks) tot 10 (ondraaglijk)?',
    inputType: ChatInputType.number,
    validator: (v) {
      final n = int.tryParse(v);
      if (n == null || n < 1 || n > 10) return 'Vul een getal in van 1 t/m 10.';
      return null;
    },
  ),

  // Pijntype
  ChatFormStep(
    id: 'pain_type',
    question: 'Hoe zou je de pijn omschrijven?',
    inputType: ChatInputType.chips,
    options: [
      ChatOption(label: 'Stekend',  value: 'sharp',     emoji: '⚡'),
      ChatOption(label: 'Kloppend', value: 'throbbing', emoji: '💗'),
      ChatOption(label: 'Stijf',    value: 'stiff',     emoji: '🧱'),
      ChatOption(label: 'Brandend', value: 'burning',   emoji: '🔥'),
      ChatOption(label: 'Trekkend', value: 'pulling',   emoji: '🎯'),
    ],
  ),

  // Wanneer pijn
  ChatFormStep(
    id: 'pain_onset',
    question: 'Wanneer voel je de pijn?',
    inputType: ChatInputType.chips,
    options: [
      ChatOption(label: 'Alleen tijdens bewegen', value: 'only_when_moving',  emoji: '🏃'),
      ChatOption(label: 'Constant',               value: 'constant',          emoji: '⏱️'),
      ChatOption(label: 'Na inspanning',          value: 'after_exertion',    emoji: '😮‍💨'),
      ChatOption(label: 'Bij aanraking/druk',     value: 'with_pressure',     emoji: '👆'),
    ],
  ),

  // Hoe lang
  ChatFormStep(
    id: 'duration',
    question: 'Hoe lang heb je al last van deze klacht?',
    inputType: ChatInputType.chips,
    options: [
      ChatOption(label: 'Minder dan 1 dag', value: '0',  emoji: '🕐'),
      ChatOption(label: '1–3 dagen',        value: '2',  emoji: '📅'),
      ChatOption(label: '3–7 dagen',        value: '5',  emoji: '📅'),
      ChatOption(label: 'Meer dan 1 week',  value: '10', emoji: '📆'),
    ],
  ),

  // Kan lopen
  ChatFormStep(
    id: 'can_walk',
    question: 'Kun je normaal lopen (stap voor stap)?',
    inputType: ChatInputType.chips,
    options: [
      ChatOption(label: 'Ja',   value: 'true',  emoji: '✅'),
      ChatOption(label: 'Nee',  value: 'false', emoji: '❌'),
    ],
  ),

  // Kan hardlopen
  ChatFormStep(
    id: 'can_run',
    question: 'Kun je (enigszins) hardlopen?',
    inputType: ChatInputType.chips,
    options: [
      ChatOption(label: 'Ja',   value: 'true',  emoji: '✅'),
      ChatOption(label: 'Nee',  value: 'false', emoji: '❌'),
    ],
  ),

  // Beschrijving (optioneel)
  ChatFormStep(
    id: 'description',
    question: 'Wil je nog iets toevoegen? (bijv. omstandigheid, eerdere blessure)',
    inputType: ChatInputType.text,
    options: [
      ChatOption(label: 'Overslaan', value: 'skip', emoji: '⏭️'),
    ],
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class InjuryChatScreen extends ConsumerStatefulWidget {
  const InjuryChatScreen({super.key});

  @override
  ConsumerState<InjuryChatScreen> createState() => _InjuryChatScreenState();
}

class _InjuryChatScreenState extends ConsumerState<InjuryChatScreen> {
  InjuryReportResult? _result;
  bool _submitting = false;
  String? _submitError;
  bool _applying = false;

  // ── ChatForm callbacks ────────────────────────────────────────────────────

  Future<String?> _onFormComplete(Map<String, dynamic> answers) async => null;

  void _onFormCompleted(Map<String, dynamic> answers) {
    _submitInjury(answers);
  }

  Future<void> _submitInjury(Map<String, dynamic> answers) async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final locationsStr = answers['location'] as String? ?? '';
      final locations = locationsStr
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final severity = int.tryParse(answers['severity']?.toString() ?? '5') ?? 5;
      final canWalk  = answers['can_walk'] == 'true';
      final canRun   = answers['can_run'] == 'true';

      final sideRaw = answers['side'] as String?;
      final side    = (sideRaw != null && sideRaw.isNotEmpty) ? sideRaw : null;

      final painType  = answers['pain_type'] as String?;
      final painOnset = answers['pain_onset'] as String?;

      final durationDays = int.tryParse(answers['duration']?.toString() ?? '');

      final descRaw   = answers['description'] as String?;
      final description =
          (descRaw != null && descRaw != 'skip' && descRaw.isNotEmpty)
              ? descRaw
              : null;

      final result = await ref.read(injuryProvider.notifier).report(
        locations:    locations,
        severity:     severity,
        canWalk:      canWalk,
        canRun:       canRun,
        side:         side,
        painType:     painType,
        painOnset:    painOnset,
        durationDays: durationDays,
        description:  description,
      );

      if (!mounted) return;
      if (result == null) {
        setState(() {
          _submitting = false;
          _submitError = 'Blessure melden mislukt. Probeer het opnieuw.';
        });
      } else {
        setState(() {
          _submitting = false;
          _result = result;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'Er ging iets mis. Probeer het opnieuw.';
      });
    }
  }

  // ── Plan adaptation actions ────────────────────────────────────────────────

  Future<void> _applyAdaptation() async {
    final result = _result;
    if (result == null || _applying) return;
    setState(() => _applying = true);
    final ok = await ref.read(injuryProvider.notifier).applyAdaptation(result.injuryId);
    if (!mounted) return;
    if (ok) {
      await ref.read(planProvider.notifier).loadActivePlan();
    }
    if (mounted) {
      if (context.canPop()) context.pop();
      else context.go('/injuries');
    }
  }

  void _skipAdaptation() {
    if (mounted) {
      if (context.canPop()) context.pop();
      else context.go('/injuries');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blessure melden'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ChatForm(
              steps: _steps,
              introMessage: 'Hoi! Ik help je een blessure te registreren 🩹\nBeantwoord de vragen, dan kijk ik of je trainingsplan aangepast moet worden.',
              completionMessage: '✅ Blessure geregistreerd. Ik controleer je plan...',
              onComplete: _onFormComplete,
              onCompleted: _onFormCompleted,
            ),
          ),
          if (_submitting)   _buildLoadingBar(),
          if (_submitError != null) _buildErrorBar(),
          if (_result != null) _buildConfirmBar(context),
        ],
      ),
    );
  }

  Widget _buildLoadingBar() {
    return Container(
      color: AppColors.surfaceHigh,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Blessure wordt opgeslagen en plan wordt geanalyseerd…',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBar() {
    return Container(
      color: AppColors.surfaceHigh,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _submitError!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBar(BuildContext context) {
    final result   = _result!;
    final preview  = result.preview;
    final weeks    = result.recoveryWeeks;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outline, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary
            Text(
              'Geschat herstel: $weeks ${weeks == 1 ? 'week' : 'weken'}.',
              style: const TextStyle(
                color: AppColors.onBg,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (preview.isEmpty)
              const Text(
                'Je trainingsplan hoeft niet aangepast te worden.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              )
            else ...[
              Text(
                '${preview.length} ${preview.length == 1 ? 'sessie wordt' : 'sessies worden'} aangepast '
                '(bijv. ${_sessionLabel(preview.first.sessionType)} → ${_sessionLabel(preview.first.newType)}).',
                style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (preview.isNotEmpty) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _applying ? null : _applyAdaptation,
                      icon: _applying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Plan aanpassen'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 130,
                    child: OutlinedButton(
                      onPressed: _applying ? null : _skipAdaptation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onBg,
                        side: const BorderSide(color: AppColors.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Plan houden'),
                    ),
                  ),
                ] else
                  Expanded(
                    child: FilledButton(
                      onPressed: _skipAdaptation,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Klaar'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
