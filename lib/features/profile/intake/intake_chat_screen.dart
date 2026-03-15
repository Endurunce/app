import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_client.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/chat/chat_form.dart';
import '../../auth/auth_provider.dart';
import '../../plan/plan_provider.dart';

class IntakeChatScreen extends ConsumerStatefulWidget {
  const IntakeChatScreen({super.key});

  @override
  ConsumerState<IntakeChatScreen> createState() => _IntakeChatScreenState();
}

class _IntakeChatScreenState extends ConsumerState<IntakeChatScreen> {
  static final _steps = <ChatFormStep>[
    // ── Persoonlijk ──
    ChatFormStep(
      id: 'name',
      question: 'Hoi! Laten we je trainingsplan samen opstellen 💪\n\nHoe mag ik je noemen?',
      inputType: ChatInputType.text,
    ),
    ChatFormStep(
      id: 'gender',
      question: 'Wat is je geslacht?',
      inputType: ChatInputType.chips,
      options: [
        ChatOption(label: 'Man', value: 'male', emoji: '♂️'),
        ChatOption(label: 'Vrouw', value: 'female', emoji: '♀️'),
        ChatOption(label: 'Anders', value: 'other', emoji: '⚧️'),
      ],
    ),
    ChatFormStep(
      id: 'date_of_birth',
      question: 'Wanneer ben je geboren?',
      inputType: ChatInputType.datePicker,
    ),

    // ── Ervaring ──
    ChatFormStep(
      id: 'running_years',
      question: 'Hoeveel jaar loop je al?',
      inputType: ChatInputType.chips,
      options: [
        ChatOption(label: 'Minder dan 1 jaar', value: 'less_than_one_year'),
        ChatOption(label: '1-2 jaar', value: 'one_to_two_years'),
        ChatOption(label: '2-5 jaar', value: 'two_to_five_years'),
        ChatOption(label: 'Meer dan 5 jaar', value: 'more_than_five_years'),
      ],
    ),
    ChatFormStep(
      id: 'weekly_km',
      question: 'Hoeveel kilometer loop je gemiddeld per week?',
      inputType: ChatInputType.number,
    ),

    // ── Prestaties (optioneel) ──
    ChatFormStep(
      id: 'time_10k',
      question: 'Wat is je beste 10K-tijd?\n\nGeen tijd? Tik "overslaan".',
      inputType: ChatInputType.durationPicker,
      options: [
        ChatOption(label: 'Overslaan', value: 'skip', emoji: '⏭️'),
      ],
    ),
    ChatFormStep(
      id: 'time_half_marathon',
      question: 'En je halve marathon?',
      inputType: ChatInputType.durationPicker,
      options: [
        ChatOption(label: 'Overslaan', value: 'skip', emoji: '⏭️'),
      ],
    ),
    ChatFormStep(
      id: 'time_marathon',
      question: 'Heb je ook een marathon gelopen? Wat was je tijd?',
      inputType: ChatInputType.durationPicker,
      options: [
        ChatOption(label: 'Overslaan', value: 'skip', emoji: '⏭️'),
      ],
    ),

    // ── Wedstrijddoel ──
    ChatFormStep(
      id: 'race_goal',
      question: 'Waar train je naartoe?',
      inputType: ChatInputType.chips,
      options: [
        ChatOption(label: '5K', value: '5k', emoji: '🏃'),
        ChatOption(label: '10K', value: '10k', emoji: '🏃'),
        ChatOption(label: 'Halve marathon', value: 'half_marathon', emoji: '🏅'),
        ChatOption(label: 'Marathon', value: 'marathon', emoji: '🏅'),
        ChatOption(label: 'Ultra', value: 'ultra', emoji: '🏔️'),
        ChatOption(label: 'Geen wedstrijd', value: 'none', emoji: '😌'),
      ],
    ),
    ChatFormStep(
      id: 'race_date',
      question: 'Wanneer is je wedstrijd? Kies een datum.',
      inputType: ChatInputType.datePicker,
      options: [
        ChatOption(label: 'Geen datum', value: 'skip', emoji: '⏭️'),
      ],
      showIf: _hasRaceGoal,
    ),
    ChatFormStep(
      id: 'terrain',
      question: 'Op wat voor ondergrond train en race je het meest?',
      inputType: ChatInputType.chips,
      options: [
        ChatOption(label: 'Weg', value: 'road', emoji: '🛣️'),
        ChatOption(label: 'Trail', value: 'trail', emoji: '🌲'),
        ChatOption(label: 'Mix', value: 'mixed', emoji: '🔀'),
      ],
    ),

    // ── Trainingsschema ──
    ChatFormStep(
      id: 'training_days',
      question: 'Op welke dagen wil je trainen? Kies minimaal 2.',
      inputType: ChatInputType.multiChips,
      minSelections: 2,
      options: [
        ChatOption(label: 'Ma', value: '0', emoji: '📅'),
        ChatOption(label: 'Di', value: '1', emoji: '📅'),
        ChatOption(label: 'Wo', value: '2', emoji: '📅'),
        ChatOption(label: 'Do', value: '3', emoji: '📅'),
        ChatOption(label: 'Vr', value: '4', emoji: '📅'),
        ChatOption(label: 'Za', value: '5', emoji: '📅'),
        ChatOption(label: 'Zo', value: '6', emoji: '📅'),
      ],
    ),
    ChatFormStep(
      id: 'long_run_day',
      question: 'Welke dag is het beste voor je lange duurloop?',
      inputType: ChatInputType.chips,
      optionsBuilder: (answers) {
        const dayLabels = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
        final raw = answers['training_days'] as String? ?? '';
        final days = raw
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toList()
          ..sort();
        return days.map((d) => ChatOption(
          label: dayLabels[d],
          value: '$d',
          emoji: '📅',
        )).toList();
      },
    ),

    // ── Gezondheid ──
    ChatFormStep(
      id: 'sleep_hours',
      question: 'Hoeveel uur slaap je gemiddeld per nacht?',
      inputType: ChatInputType.chips,
      options: [
        ChatOption(label: 'Minder dan 6', value: 'less_than_six'),
        ChatOption(label: '6-7 uur', value: 'six_to_seven'),
        ChatOption(label: '7-8 uur', value: 'seven_to_eight'),
        ChatOption(label: 'Meer dan 8', value: 'more_than_eight'),
      ],
    ),
    ChatFormStep(
      id: 'complaints',
      question: 'Heb je klachten of blessures waar ik rekening mee moet houden?',
      inputType: ChatInputType.text,
      options: [
        ChatOption(label: 'Nee, alles goed!', value: 'skip', emoji: '✅'),
      ],
    ),
  ];

  static bool _hasRaceGoal(Map<String, dynamic> answers) {
    final goal = answers['race_goal'] as String?;
    return goal != null && goal != 'none';
  }

  // ── Confirmation phase state ───────────────────────────────────────────────

  String? _planSummary;
  bool _generating = false;
  String? _generateError;
  bool _regenerating = false;
  bool _showFeedbackField = false;
  final _feedbackCtrl = TextEditingController();

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  // ── Intake submission ──────────────────────────────────────────────────────

  /// Called by ChatForm when all questions are answered.
  /// Returns null immediately so ChatForm shows the completionMessage.
  /// The actual API call happens in [_onFormCompleted].
  Future<String?> _onFormComplete(Map<String, dynamic> answers) async => null;

  /// Called by ChatForm after it has finished and shown the completion message.
  void _onFormCompleted(Map<String, dynamic> answers) {
    _generatePlan(answers);
  }

  Future<void> _generatePlan(Map<String, dynamic> answers) async {
    if (!mounted) return;
    FocusScope.of(context).unfocus(); // dismiss keyboard so the bars are visible
    setState(() {
      _generating = true;
      _generateError = null;
    });

    try {
      final client = ref.read(apiClientProvider);

      final weeklyKm = double.tryParse(answers['weekly_km']?.toString() ?? '0') ?? 0;

      String? formatTime(String? val) {
        if (val == null || val == 'skip' || val.isEmpty) return null;
        return val;
      }

      final raceDateRaw = answers['race_date'] as String?;
      final raceDate =
          (raceDateRaw != null && raceDateRaw != 'skip') ? raceDateRaw : null;

      final complaints = answers['complaints'] as String?;

      final trainingDaysStr = answers['training_days'] as String? ?? '';
      final trainingDays = trainingDaysStr
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList()
        ..sort();

      final longRunDayRaw = answers['long_run_day'] as String?;
      final longRunDay = int.tryParse(longRunDayRaw ?? '') ??
          (trainingDays.isNotEmpty ? trainingDays.last : 6);

      final profile = {
        'name': answers['name'],
        'date_of_birth': answers['date_of_birth'],
        'gender': answers['gender'] ?? 'other',
        'running_years': answers['running_years'] ?? 'two_to_five_years',
        'weekly_km': weeklyKm,
        'time_10k': formatTime(answers['time_10k'] as String?),
        'time_half_marathon': formatTime(answers['time_half_marathon'] as String?),
        'time_marathon': formatTime(answers['time_marathon'] as String?),
        'race_goal': answers['race_goal'] ?? 'none',
        'race_date': raceDate,
        'terrain': answers['terrain'] ?? 'road',
        'training_days': trainingDays,
        'long_run_day': longRunDay,
        'sleep_hours': answers['sleep_hours'] ?? 'seven_to_eight',
        if (complaints != null && complaints != 'skip') 'complaints': complaints,
      };

      final result =
          await client.post('/api/plans/generate', {'profile': profile});

      final summary = result['summary'] as String? ??
          'Je trainingsplan is klaar!';

      if (!mounted) return;
      setState(() {
        _generating = false;
        _planSummary = summary;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _generateError = 'Er ging iets mis. Probeer het opnieuw.';
      });
    }
  }

  // ── Confirm / regenerate ───────────────────────────────────────────────────

  void _confirmPlan() {
    ref.read(authProvider.notifier).markIntakeCompleted();
    // Router redirect handles the navigation; context.go is a fallback.
    if (mounted) context.go('/plan');
  }

  Future<void> _regeneratePlan() async {
    final feedback = _feedbackCtrl.text.trim();
    if (_regenerating) return;
    setState(() {
      _regenerating = true;
      _showFeedbackField = false;
    });
    try {
      final client = ref.read(apiClientProvider);
      final result = await client.post('/api/plans/regenerate', {
        if (feedback.isNotEmpty) 'feedback': feedback,
      });
      final summary = result['summary'] as String? ??
          'Je plan is bijgewerkt!';
      if (mounted) {
        setState(() {
          _planSummary = summary;
          _feedbackCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(summary),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kon plan niet bijwerken. Probeer opnieuw.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _showFeedbackField = true);
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final intakeCompleted = ref.watch(authProvider.select((s) => s.intakeCompleted));

    // Still checking — show a neutral loading screen so the shell never mounts.
    if (intakeCompleted == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Intake')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ChatForm(
              steps: _steps,
              disclaimerText:
                  'Beantwoord de vragen om je persoonlijke trainingsplan te maken.',
              completionMessage:
                  '✅ Alles duidelijk! Ik ga nu je trainingsplan opstellen...',
              onComplete: _onFormComplete,
              onCompleted: _onFormCompleted,
            ),
          ),
          // Loading overlay while generating
          if (_generating) _buildGeneratingBar(),
          // Error state
          if (_generateError != null) _buildErrorBar(),
          // Confirm / feedback bar once plan is ready
          if (_planSummary != null) _buildConfirmBar(context),
        ],
      ),
    );
  }

  Widget _buildGeneratingBar() {
    return Container(
      width: double.infinity,
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
              'AI is je trainingsplan aan het opstellen… Dit duurt even.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBar() {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceHigh,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _generateError!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outline, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plan summary
            if (_planSummary != null) ...[
              Text(
                _planSummary!,
                style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
            ],
            // Feedback input (shown when user taps "Pas aan")
            if (_showFeedbackField) ...[
              TextField(
                controller: _feedbackCtrl,
                autofocus: true,
                maxLines: 2,
                style: const TextStyle(color: AppColors.onBg, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Wat wil je anders? Bijv. "meer rustdagen" of "hogere piek"',
                  hintStyle:
                      TextStyle(color: AppColors.muted.withValues(alpha: 0.6), fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                // Confirm button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _regenerating ? null : _confirmPlan,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Bevestig plan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Adjust button — fixed width to avoid unconstrained layout crash
                SizedBox(
                  width: 130,
                  child: _showFeedbackField
                      ? FilledButton(
                          onPressed: _regenerating ? null : _regeneratePlan,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.surfaceHigh,
                            foregroundColor: AppColors.onBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: AppColors.outline),
                            ),
                          ),
                          child: _regenerating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.brand),
                                )
                              : const Text('Pas aan'),
                        )
                      : OutlinedButton(
                          onPressed: _regenerating
                              ? null
                              : () => setState(() => _showFeedbackField = true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onBg,
                            side: const BorderSide(color: AppColors.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune, size: 16),
                              SizedBox(width: 6),
                              Text('Pas aan'),
                            ],
                          ),
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
