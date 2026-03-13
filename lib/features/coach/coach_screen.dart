import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/chat/chat_view.dart';
import 'coach_ws_provider.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  static const _suggestions = [
    'Hoe herstel ik sneller?',
    'Pas mijn plan aan',
    'Wat is mijn focuspunt deze week?',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(coachWsProvider.notifier).connect());
  }

  @override
  void dispose() {
    ref.read(coachWsProvider.notifier).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachWsProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Coach'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: state.connected ? AppColors.brand : AppColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ChatView(
        messages: state.messages,
        connected: state.connected,
        thinking: state.thinking,
        activeTool: state.activeTool,
        intakeActive: state.intakeActive,
        quickReplyState: state.quickReplyState,
        error: state.error,
        onSend: (text) => ref.read(coachWsProvider.notifier).send(text),
        onQuickReply: (value, label) =>
            ref.read(coachWsProvider.notifier).sendQuickReply(value, label),
        config: const ChatViewConfig(
          disclaimerText:
              'Ik ben een AI-coach, geen medisch professional. Raadpleeg een arts bij twijfel over je gezondheid of blessures.',
          suggestions: _suggestions,
          emptyState: _EmptyState(),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            Text('Hoi! Ik ben je AI-coach.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Stel me vragen over je training, herstel of race-strategie. Ik gebruik je profiel en trainingsdata als context.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
