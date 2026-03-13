import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_client.dart';
import '../../../shared/widgets/chat/chat_form.dart';
import '../../plan/plan_provider.dart';

class IntakeChatScreen extends ConsumerWidget {
  const IntakeChatScreen({super.key});

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
      question: 'Wat is je beste 10K-tijd? (MM:SS of HH:MM:SS)\n\nGeen tijd? Tik "overslaan".',
      inputType: ChatInputType.durationPicker,
      options: [
        ChatOption(label: 'Overslaan', value: 'skip', emoji: '⏭️'),
      ],
    ),
    ChatFormStep(
      id: 'time_half_marathon',
      question: 'En je halve marathon? (HH:MM:SS)',
      inputType: ChatInputType.durationPicker,
      options: [
        ChatOption(label: 'Overslaan', value: 'skip', emoji: '⏭️'),
      ],
    ),
    ChatFormStep(
      id: 'time_marathon',
      question: 'Heb je ook een marathon gelopen? Wat was je tijd? (HH:MM:SS)',
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
      options: [
        ChatOption(label: 'Zaterdag', value: '5', emoji: '📅'),
        ChatOption(label: 'Zondag', value: '6', emoji: '📅'),
        ChatOption(label: 'Andere dag', value: 'other', emoji: '🔄'),
      ],
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
      question: 'Heb je op dit moment klachten of blessures waar ik rekening mee moet houden?',
      inputType: ChatInputType.text,
      options: [
        ChatOption(label: 'Nee, alles goed!', value: 'skip', emoji: '✅'),
      ],
    ),
  ];

  /// Guard: only show race_date when the user has an actual race goal.
  static bool _hasRaceGoal(Map<String, dynamic> answers) {
    final goal = answers['race_goal'] as String?;
    return goal != null && goal != 'none';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Intake')),
      body: ChatForm(
        steps: _steps,
        disclaimerText:
            'Beantwoord de vragen om je persoonlijke trainingsplan te maken.',
        completionMessage:
            '✅ Top! Ik heb alles wat ik nodig heb. Je trainingsplan wordt nu gegenereerd...',
        doneButtonLabel: 'Naar mijn plan',
        onComplete: (answers) => _submitIntake(ref, answers),
        onDone: () => context.go('/plan'),
      ),
    );
  }

  Future<String?> _submitIntake(WidgetRef ref, Map<String, dynamic> answers) async {
    try {
      final client = ref.read(apiClientProvider);

      final weeklyKm = double.tryParse(answers['weekly_km'] ?? '0') ?? 0;

      String? formatTime(String? val) {
        if (val == null || val == 'skip' || val.isEmpty) return null;
        return val;
      }

      final raceDateRaw = answers['race_date'] as String?;
      final raceDate = (raceDateRaw != null && raceDateRaw != 'skip')
          ? raceDateRaw
          : null;

      final complaints = answers['complaints'] as String?;

      // Parse training days from comma-separated string
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
        'time_10k': formatTime(answers['time_10k']),
        'time_half_marathon': formatTime(answers['time_half_marathon']),
        'time_marathon': formatTime(answers['time_marathon']),
        'race_goal': answers['race_goal'] ?? 'none',
        'race_date': raceDate,
        'terrain': answers['terrain'] ?? 'road',
        'training_days': trainingDays,
        'long_run_day': longRunDay,
        'sleep_hours': answers['sleep_hours'] ?? 'seven_to_eight',
        if (complaints != null && complaints != 'skip')
          'complaints': complaints,
      };

      await client.post('/api/plans/generate', {'profile': profile});
      await ref.read(planProvider.notifier).loadActivePlan();
      return '🎉 Je trainingsplan is klaar! Tik hieronder om het te bekijken.';
    } catch (e) {
      return '❌ Er ging iets mis bij het genereren van je plan. Probeer het later opnieuw.';
    }
  }
}
