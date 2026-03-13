import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'chat_view.dart';
import 'message_bubble.dart';
import 'quick_replies.dart';
import 'typing_indicator.dart';

// ── Form models ────────────────────────────────────────────────────────────────

/// Input types supported by the chat form.
enum ChatInputType {
  /// Single-select chips.
  chips,

  /// Multi-select chips with confirm button.
  multiChips,

  /// Native date picker.
  datePicker,

  /// Number text field.
  number,

  /// HH:MM:SS duration text field.
  durationPicker,

  /// Free text field.
  text,
}

/// A single option for chips / multiChips.
class ChatOption {
  final String label;
  final String value;
  final String? emoji;

  const ChatOption({
    required this.label,
    required this.value,
    this.emoji,
  });
}

/// A single step (question) in the chat form.
class ChatFormStep {
  /// Unique identifier for this step's answer.
  final String id;

  /// The question text shown as an assistant bubble.
  final String question;

  /// What kind of input to show.
  final ChatInputType inputType;

  /// Options for [ChatInputType.chips] and [ChatInputType.multiChips].
  final List<ChatOption> options;

  /// Optional validation. Return an error string to reject, null to accept.
  final String? Function(String value)? validator;

  /// Optional guard — if provided, this step is only shown when the predicate
  /// returns true given the answers collected so far.
  final bool Function(Map<String, dynamic> answers)? showIf;

  const ChatFormStep({
    required this.id,
    required this.question,
    required this.inputType,
    this.options = const [],
    this.validator,
    this.showIf,
  });
}

/// Result passed to [ChatForm.onComplete].
typedef ChatFormResult = Map<String, dynamic>;

// ── ChatForm widget ────────────────────────────────────────────────────────────

/// A declarative form rendered as a chat conversation.
///
/// Feed it a list of [ChatFormStep]s and it will walk the user through them
/// one by one, displaying each question as an assistant bubble and the user's
/// answer as a user bubble. On completion it calls [onComplete] with a map of
/// `{stepId: answerValue}`.
class ChatForm extends StatefulWidget {
  /// The ordered list of form steps.
  final List<ChatFormStep> steps;

  /// Optional intro message shown before the first question.
  final String? introMessage;

  /// Optional message shown after all steps are answered (before [onComplete]).
  final String? completionMessage;

  /// Optional disclaimer banner at the top.
  final String? disclaimerText;

  /// Called with all collected answers when the form is complete.
  /// Return a `Future<String?>` — if non-null the string is shown as a final
  /// assistant message; if null the [completionMessage] is used.
  final Future<String?> Function(ChatFormResult answers)? onComplete;

  /// Called when the form completes and the user taps a "done" action.
  /// Useful for navigation (e.g. `context.pop()`).
  final VoidCallback? onDone;

  /// Label for the done button shown after completion.
  final String doneButtonLabel;

  /// Simulated typing delay before showing each question (ms).
  final int typingDelayMs;

  const ChatForm({
    super.key,
    required this.steps,
    this.introMessage,
    this.completionMessage,
    this.disclaimerText,
    this.onComplete,
    this.onDone,
    this.doneButtonLabel = 'Klaar',
    this.typingDelayMs = 600,
  });

  @override
  State<ChatForm> createState() => _ChatFormState();
}

class _ChatFormState extends State<ChatForm> {
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  final Map<String, dynamic> _answers = {};

  int _msgCounter = 0;
  int _currentStepIndex = -1; // -1 = not started yet
  bool _thinking = false;
  bool _submitting = false;
  bool _completed = false;
  String? _error;
  QuickReplyState? _quickReplyState;

  @override
  void initState() {
    super.initState();
    _startForm();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Flow control ───────────────────────────────────────────────────────────

  Future<void> _startForm() async {
    if (widget.introMessage != null) {
      setState(() => _thinking = true);
      await Future.delayed(Duration(milliseconds: widget.typingDelayMs));
      if (!mounted) return;
      _addAssistantMessage(widget.introMessage!);
      setState(() => _thinking = false);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }
    _advanceToNextStep();
  }

  void _advanceToNextStep() {
    // Find the next applicable step
    int nextIndex = _currentStepIndex + 1;
    while (nextIndex < widget.steps.length) {
      final step = widget.steps[nextIndex];
      if (step.showIf == null || step.showIf!(_answers)) {
        break;
      }
      nextIndex++;
    }

    if (nextIndex >= widget.steps.length) {
      _finishForm();
      return;
    }

    _currentStepIndex = nextIndex;
    final step = widget.steps[_currentStepIndex];

    // Show typing indicator, then question
    setState(() => _thinking = true);
    Future.delayed(Duration(milliseconds: widget.typingDelayMs), () {
      if (!mounted) return;
      _addAssistantMessage(step.question);
      setState(() {
        _thinking = false;
        _quickReplyState = _buildQuickReplyState(step);
      });
      _scrollToBottom();
    });
  }

  QuickReplyState _buildQuickReplyState(ChatFormStep step) {
    final options = step.options
        .map((o) => QuickReplyOption(label: o.label, value: o.value, emoji: o.emoji))
        .toList();

    final inputType = switch (step.inputType) {
      ChatInputType.chips => null, // default
      ChatInputType.multiChips => 'multi_chips',
      ChatInputType.datePicker => 'date_picker',
      ChatInputType.number => 'number',
      ChatInputType.durationPicker => 'duration_picker',
      ChatInputType.text => 'text',
    };

    return QuickReplyState(
      questionId: step.id,
      options: options,
      inputType: inputType,
    );
  }

  void _onAnswer(String value, String displayLabel) {
    final step = widget.steps[_currentStepIndex];

    // Validate
    if (step.validator != null) {
      final errorMsg = step.validator!(value);
      if (errorMsg != null) {
        setState(() => _error = errorMsg);
        // Re-show the same quick reply state after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _error = null);
        });
        return;
      }
    }

    // Record answer
    _answers[step.id] = value;

    // Show user bubble
    _addUserMessage(displayLabel);
    setState(() {
      _quickReplyState = null;
      _error = null;
    });

    // Small delay before next question
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _advanceToNextStep();
    });
  }

  Future<void> _finishForm() async {
    setState(() {
      _submitting = true;
      _thinking = true;
      _quickReplyState = null;
    });

    try {
      String? resultMessage;
      if (widget.onComplete != null) {
        resultMessage = await widget.onComplete!(_answers);
      }

      if (!mounted) return;

      final finalMsg = resultMessage ?? widget.completionMessage;
      if (finalMsg != null) {
        _addAssistantMessage(finalMsg);
      }

      setState(() {
        _thinking = false;
        _submitting = false;
        _completed = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _submitting = false;
        _error = 'Er ging iets mis. Probeer opnieuw.';
      });
    }

    _scrollToBottom();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _addAssistantMessage(String content) {
    _msgCounter++;
    _messages.add(ChatMessage(
      id: 'assistant_$_msgCounter',
      role: 'assistant',
      content: content,
      createdAt: DateTime.now(),
    ));
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  void _addUserMessage(String content) {
    _msgCounter++;
    _messages.add(ChatMessage(
      id: 'user_$_msgCounter',
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    ));
    if (mounted) setState(() {});
    _scrollToBottom();
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Disclaimer banner
        if (widget.disclaimerText != null)
          Container(
            width: double.infinity,
            color: AppColors.surfaceHigh,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.disclaimerText!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

        // Messages list
        Expanded(
          child: _messages.isEmpty && !_thinking
              ? const SizedBox.shrink()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: _messages.length + (_thinking ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i < _messages.length) {
                      return MessageBubble(message: _messages[i]);
                    }
                    return const TypingBubble();
                  },
                ),
        ),

        // Quick replies / input
        if (_quickReplyState != null)
          QuickRepliesBar(
            questionId: _quickReplyState!.questionId,
            options: _quickReplyState!.options,
            inputType: _quickReplyState!.inputType,
            onSelect: _onAnswer,
          ),

        // Validation error
        if (_error != null)
          Container(
            width: double.infinity,
            color: AppColors.errorDim,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

        // Done button
        if (_completed && widget.onDone != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: FilledButton(
                onPressed: widget.onDone,
                child: Text(widget.doneButtonLabel),
              ),
            ),
          ),
      ],
    );
  }
}
