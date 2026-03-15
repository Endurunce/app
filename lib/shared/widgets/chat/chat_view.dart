import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'input_bar.dart';
import 'message_bubble.dart';
import 'quick_replies.dart';
import 'suggestion_bar.dart';
import 'typing_indicator.dart';

// ── Generic chat models ────────────────────────────────────────────────────────

/// A single chat message (user or assistant).
class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  ChatMessage copyWith({String? content}) => ChatMessage(
    id: id,
    role: role,
    content: content ?? this.content,
    createdAt: createdAt,
  );
}

/// A quick reply option (chip).
class QuickReplyOption {
  final String label;
  final String value;
  final String? emoji;

  const QuickReplyOption({
    required this.label,
    required this.value,
    this.emoji,
  });
}

/// Configuration for the quick replies bar.
class QuickReplyState {
  final String questionId;
  final List<QuickReplyOption> options;
  final String? inputType; // chips, multi_chips, date_picker, number, duration_picker, text
  final int minSelections;

  const QuickReplyState({
    required this.questionId,
    required this.options,
    this.inputType,
    this.minSelections = 1,
  });
}

/// Configuration for the ChatView.
class ChatViewConfig {
  /// Whether to show the free-text input bar.
  final bool showInputBar;

  /// Optional disclaimer text shown at the top.
  final String? disclaimerText;

  /// Optional suggestions shown when chat is near-empty.
  final List<String> suggestions;

  /// Custom empty state widget.
  final Widget? emptyState;

  /// Maximum number of messages before hiding suggestions.
  final int suggestionsMaxMessages;

  const ChatViewConfig({
    this.showInputBar = true,
    this.disclaimerText,
    this.suggestions = const [],
    this.emptyState,
    this.suggestionsMaxMessages = 3,
  });
}

// ── ChatView widget ────────────────────────────────────────────────────────────

class ChatView extends StatefulWidget {
  /// Chat messages to display.
  final List<ChatMessage> messages;

  /// Whether the backend is connected.
  final bool connected;

  /// Whether the assistant is currently thinking.
  final bool thinking;

  /// Name of the currently active tool (null if none).
  final String? activeTool;

  /// Whether an intake flow is active (used to conditionally hide suggestions).
  final bool intakeActive;

  /// Current quick reply state (null if no quick replies shown).
  final QuickReplyState? quickReplyState;

  /// Error message to display (null if no error).
  final String? error;

  /// Callback when user sends a free-text message.
  final void Function(String text)? onSend;

  /// Callback when user selects a quick reply.
  final void Function(String value, String label)? onQuickReply;

  /// View configuration.
  final ChatViewConfig config;

  const ChatView({
    super.key,
    required this.messages,
    this.connected = false,
    this.thinking = false,
    this.activeTool,
    this.intakeActive = false,
    this.quickReplyState,
    this.error,
    this.onSend,
    this.onQuickReply,
    this.config = const ChatViewConfig(),
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
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
    widget.onSend?.call(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isNotEmpty || widget.thinking) _scrollToBottom();

    final hasQuickReplies = widget.quickReplyState != null;
    final showSuggestions = !hasQuickReplies &&
        !widget.intakeActive &&
        widget.config.suggestions.isNotEmpty &&
        widget.messages.length < widget.config.suggestionsMaxMessages;

    return Column(
      children: [
        // Disclaimer banner
        if (widget.config.disclaimerText != null)
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
                    widget.config.disclaimerText!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

        // Messages list
        Expanded(
          child: widget.messages.isEmpty && !widget.thinking
              ? (widget.config.emptyState ?? const SizedBox.shrink())
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: widget.messages.length +
                      (widget.activeTool != null ? 1 : 0) +
                      (widget.thinking ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i < widget.messages.length) {
                      return MessageBubble(message: widget.messages[i]);
                    }

                    final extraIndex = i - widget.messages.length;

                    if (widget.activeTool != null && extraIndex == 0) {
                      return ToolIndicator(toolName: widget.activeTool!);
                    }

                    return const TypingBubble();
                  },
                ),
        ),

        // Quick reply buttons
        if (hasQuickReplies)
          QuickRepliesBar(
            questionId: widget.quickReplyState!.questionId,
            options: widget.quickReplyState!.options,
            inputType: widget.quickReplyState!.inputType,
            minSelections: widget.quickReplyState!.minSelections,
            onSelect: (value, label) {
              widget.onQuickReply?.call(value, label);
              _scrollToBottom();
            },
          ),

        // Suggestions
        if (showSuggestions)
          SuggestionBar(suggestions: widget.config.suggestions, onTap: _send),

        // Error banner
        if (widget.error != null)
          Container(
            width: double.infinity,
            color: AppColors.errorDim,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

        // Input bar
        if (widget.config.showInputBar)
          InputBar(
            controller: _inputCtrl,
            sending: widget.thinking,
            onSend: _send,
          ),
      ],
    );
  }
}
