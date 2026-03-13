import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/chat/chat_form.dart';
import '../injury/injury_provider.dart';
import '../plan/plan_provider.dart';

class InjuryChatScreen extends ConsumerWidget {
  const InjuryChatScreen({super.key});

  static const _steps = <ChatFormStep>[
    ChatFormStep(
      id: 'location',
      question: 'Waar zit de pijn? Je kunt meerdere locaties kiezen.',
      inputType: ChatInputType.multiChips,
      options: [
        ChatOption(label: 'Knie', value: 'knee', emoji: '🦵'),
        ChatOption(label: 'Achilles', value: 'achilles', emoji: '🦶'),
        ChatOption(label: 'Scheenbeen', value: 'shin', emoji: '🦷'),
        ChatOption(label: 'Heup', value: 'hip', emoji: '🫀'),
        ChatOption(label: 'Hamstring', value: 'hamstring', emoji: '🏃'),
        ChatOption(label: 'Kuit', value: 'calf', emoji: '🦵'),
        ChatOption(label: 'Voet', value: 'foot', emoji: '🦶'),
        ChatOption(label: 'Enkel', value: 'ankle', emoji: '🦶'),
        ChatOption(label: 'Onderrug', value: 'lower_back', emoji: '🔙'),
        ChatOption(label: 'Schouder', value: 'shoulder', emoji: '💪'),
        ChatOption(label: 'IT-band', value: 'it_band', emoji: '🦵'),
      ],
    ),
    ChatFormStep(
      id: 'severity',
      question: 'Hoe erg is de pijn op een schaal van 1 tot 10?',
      inputType: ChatInputType.number,
    ),
    ChatFormStep(
      id: 'can_walk',
      question: 'Kun je normaal lopen?',
      inputType: ChatInputType.chips,
      options: [
        ChatOption(label: 'Ja', value: 'true', emoji: '✅'),
        ChatOption(label: 'Nee', value: 'false', emoji: '❌'),
      ],
    ),
    ChatFormStep(
      id: 'can_run',
      question: 'Kun je hardlopen?',
      inputType: ChatInputType.chips,
      options: [
        ChatOption(label: 'Ja', value: 'true', emoji: '✅'),
        ChatOption(label: 'Nee', value: 'false', emoji: '❌'),
      ],
    ),
    ChatFormStep(
      id: 'description',
      question: 'Wil je nog iets toevoegen? Beschrijf de blessure kort.',
      inputType: ChatInputType.text,
      options: [
        ChatOption(label: 'Overslaan', value: 'skip', emoji: '⏭️'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Blessure melden'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ChatForm(
        steps: _steps,
        introMessage: 'Hoi! Ik help je een blessure te melden 🩹',
        completionMessage:
            '✅ Blessure geregistreerd. Je plan wordt aangepast aan je herstel.',
        doneButtonLabel: 'Terug naar blessures',
        onComplete: (answers) => _submitInjury(ref, answers),
        onDone: () => context.pop(),
      ),
    );
  }

  Future<String?> _submitInjury(WidgetRef ref, Map<String, dynamic> answers) async {
    try {
      final locationsStr = answers['location'] as String? ?? '';
      final locations = locationsStr.split(',').map((s) => s.trim()).toList();
      final severity = int.tryParse(answers['severity'] ?? '5') ?? 5;
      final canWalk = answers['can_walk'] == 'true';
      final canRun = answers['can_run'] == 'true';
      final descRaw = answers['description'] as String?;
      final description =
          (descRaw != null && descRaw != 'skip' && descRaw.isNotEmpty)
              ? descRaw
              : null;

      final msg = await ref.read(injuryProvider.notifier).report(
        locations: locations,
        severity: severity,
        canWalk: canWalk,
        canRun: canRun,
        description: description,
      );

      if (msg != null) {
        await ref.read(planProvider.notifier).loadActivePlan();
      }

      return msg ?? '✅ Blessure gemeld! Je plan is aangepast.';
    } catch (e) {
      return '❌ Blessure melden mislukt. Probeer het later opnieuw.';
    }
  }
}
