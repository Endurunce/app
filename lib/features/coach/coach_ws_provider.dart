import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/coach_service.dart';
import '../plan/plan_provider.dart';

// ── Models ─────────────────────────────────────────────────────────────────────

class CoachMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  const CoachMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  CoachMessage copyWith({String? content}) => CoachMessage(
    id: id,
    role: role,
    content: content ?? this.content,
    createdAt: createdAt,
  );
}

// ── State ──────────────────────────────────────────────────────────────────────

class CoachWsState {
  final List<CoachMessage> messages;
  final bool connected;
  final bool thinking;          // agent is processing (between user msg and first delta)
  final String? activeTool;     // tool currently being used by agent
  final String? error;

  const CoachWsState({
    this.messages = const [],
    this.connected = false,
    this.thinking = false,
    this.activeTool,
    this.error,
  });

  CoachWsState copyWith({
    List<CoachMessage>? messages,
    bool? connected,
    bool? thinking,
    String? activeTool,
    bool clearTool = false,
    String? error,
    bool clearError = false,
  }) => CoachWsState(
    messages:   messages   ?? this.messages,
    connected:  connected  ?? this.connected,
    thinking:   thinking   ?? this.thinking,
    activeTool: clearTool ? null : (activeTool ?? this.activeTool),
    error:      clearError ? null : (error ?? this.error),
  );
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class CoachWsNotifier extends Notifier<CoachWsState> {
  CoachService? _service;
  StreamSubscription<CoachEvent>? _sub;
  Timer? _reconnectTimer;
  int _msgCounter = 0;

  @override
  CoachWsState build() => const CoachWsState();

  /// Connect to the coach WebSocket and load conversation history.
  Future<void> connect() async {
    final token = await getToken();
    if (token == null) {
      state = state.copyWith(error: 'Niet ingelogd.');
      return;
    }

    await _cleanup();

    // Load conversation history from backend
    try {
      final api = ref.read(apiClientProvider);
      final history = await api.get('/api/conversations') as List<dynamic>;
      final messages = history.map<CoachMessage>((m) {
        _msgCounter++;
        return CoachMessage(
          id: '${m['role']}_$_msgCounter',
          role: m['role'] as String,
          content: m['content'] as String,
          createdAt: DateTime.now(),
        );
      }).toList();
      state = state.copyWith(messages: messages, clearError: true);
    } catch (_) {
      // History load failed — continue without it
    }

    _service = CoachService();
    _sub = _service!.events.listen(_onEvent);

    state = state.copyWith(clearError: true);
    await _service!.connect(token);
    state = state.copyWith(connected: true);
  }

  /// Send a user message.
  void send(String content) {
    final text = content.trim();
    if (text.isEmpty || _service == null) return;

    _msgCounter++;
    final msg = CoachMessage(
      id: 'user_$_msgCounter',
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, msg],
      thinking: true,
      clearError: true,
      clearTool: true,
    );

    _service!.send(text);
  }

  void _onEvent(CoachEvent event) {
    switch (event) {
      case TextDelta(:final delta):
        _appendDelta(delta);
      case ToolUseStart(:final toolName):
        state = state.copyWith(activeTool: toolName, thinking: false);
      case ToolResult():
        state = state.copyWith(clearTool: true);
      case PlanUpdated():
        state = state.copyWith(clearTool: true);
        // Refresh the plan data
        ref.read(planProvider.notifier).loadActivePlan();
      case MessageEnd():
        state = state.copyWith(thinking: false, clearTool: true);
      case ConnectionError(:final error):
        state = state.copyWith(
          connected: false,
          thinking: false,
          clearTool: true,
          error: error,
        );
        _scheduleReconnect();
      case ConnectionClosed():
        state = state.copyWith(connected: false, thinking: false, clearTool: true);
        _scheduleReconnect();
    }
  }

  /// Append a text delta to the current assistant message, or create one.
  void _appendDelta(String delta) {
    final msgs = List<CoachMessage>.from(state.messages);

    if (msgs.isNotEmpty && msgs.last.role == 'assistant') {
      msgs[msgs.length - 1] = msgs.last.copyWith(
        content: msgs.last.content + delta,
      );
    } else {
      _msgCounter++;
      msgs.add(CoachMessage(
        id: 'assistant_$_msgCounter',
        role: 'assistant',
        content: delta,
        createdAt: DateTime.now(),
      ));
    }

    state = state.copyWith(messages: msgs, thinking: false);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!state.connected) {
        connect();
      }
    });
  }

  Future<void> _cleanup() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _sub?.cancel();
    _sub = null;
    await _service?.dispose();
    _service = null;
  }

  /// Disconnect.
  Future<void> disconnect() async {
    await _cleanup();
    state = state.copyWith(connected: false, thinking: false, clearTool: true);
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

final coachWsProvider =
    NotifierProvider<CoachWsNotifier, CoachWsState>(CoachWsNotifier.new);
