import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import 'coach_ws_provider.dart';
import 'widgets/input_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/quick_replies.dart';
import 'widgets/suggestion_bar.dart';
import 'widgets/typing_indicator.dart';

class CoachScreen extends ConsumerStatefulWidget {
  final bool startIntake;
  const CoachScreen({super.key, this.startIntake = false});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _suggestions = [
    'Hoe herstel ik sneller?',
    'Pas mijn plan aan',
    'Wat is mijn focuspunt deze week?',
  ];

  bool _intakeStarted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(coachWsProvider.notifier).connect();
      if (widget.startIntake && !_intakeStarted) {
        _intakeStarted = true;
        // Small delay to ensure WebSocket is connected
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          ref.read(coachWsProvider.notifier).startIntake();
        }
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    ref.read(coachWsProvider.notifier).disconnect();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    ref.read(coachWsProvider.notifier).send(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachWsProvider);

    if (state.messages.isNotEmpty || state.thinking) _scrollToBottom();

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
      body: Column(
        children: [
          // Disclaimer banner
          Container(
            width: double.infinity,
            color: AppColors.surfaceHigh,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ik ben een AI-coach, geen medisch professional. Raadpleeg een arts bij twijfel over je gezondheid of blessures.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: state.messages.isEmpty && !state.thinking
                ? const _EmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: state.messages.length +
                        (state.activeTool != null ? 1 : 0) +
                        (state.thinking ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i < state.messages.length) {
                        return MessageBubble(message: state.messages[i]);
                      }

                      final extraIndex = i - state.messages.length;

                      if (state.activeTool != null && extraIndex == 0) {
                        return ToolIndicator(toolName: state.activeTool!);
                      }

                      return const TypingBubble();
                    },
                  ),
          ),

          // Quick reply buttons (intake or contextual)
          if (state.quickReplies != null && state.quickReplies!.isNotEmpty)
            QuickRepliesBar(
              questionId: state.quickReplyQuestionId ?? '',
              options: state.quickReplies!,
              onSelect: (value, label) {
                ref.read(coachWsProvider.notifier).sendQuickReply(value, label);
                _scrollToBottom();
              },
            ),

          // Quick suggestions (only when not in intake and no quick replies)
          if (state.quickReplies == null &&
              !state.intakeActive &&
              state.messages.length < 3)
            SuggestionBar(suggestions: _suggestions, onTap: _send),

          // Error banner
          if (state.error != null)
            Container(
              width: double.infinity,
              color: AppColors.errorDim,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                state.error!,
                style:
                    const TextStyle(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          // Input bar
          InputBar(
            controller: _inputCtrl,
            sending: state.thinking,
            onSend: _send,
          ),
        ],
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
