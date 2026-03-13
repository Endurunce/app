import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

// ── WebSocket URL ──────────────────────────────────────────────────────────────
// Derives from API_URL: https://x → wss://x, http://x → ws://x

const _apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000',
);

final String _wsBase = _apiUrl
    .replaceFirst('https://', 'wss://')
    .replaceFirst('http://', 'ws://');

// ── Event types from the agent ─────────────────────────────────────────────────

sealed class CoachEvent {}

class TextDelta extends CoachEvent {
  final String delta;
  TextDelta(this.delta);
}

class ToolUseStart extends CoachEvent {
  final String toolName;
  ToolUseStart(this.toolName);
}

class ToolResult extends CoachEvent {
  final String toolName;
  final Map<String, dynamic> result;
  ToolResult(this.toolName, this.result);
}

class PlanUpdated extends CoachEvent {
  final String planId;
  final int week;
  PlanUpdated(this.planId, this.week);
}

class MessageEnd extends CoachEvent {
  final int inputTokens;
  final int outputTokens;
  MessageEnd(this.inputTokens, this.outputTokens);
}

class ConnectionError extends CoachEvent {
  final String error;
  ConnectionError(this.error);
}

class QuickRepliesEvent extends CoachEvent {
  final String questionId;
  final List<QuickReplyOption> options;
  final String? inputType; // chips, multi_chips, date_picker, number, duration_picker, text
  QuickRepliesEvent(this.questionId, this.options, this.inputType);
}

class QuickReplyOption {
  final String label;
  final String value;
  final String? emoji;
  QuickReplyOption(this.label, this.value, this.emoji);

  factory QuickReplyOption.fromJson(Map<String, dynamic> j) => QuickReplyOption(
    j['label'] as String? ?? '',
    j['value'] as String? ?? '',
    j['emoji'] as String?,
  );
}

class ConnectionClosed extends CoachEvent {}

// ── Service ────────────────────────────────────────────────────────────────────

class CoachService {
  WebSocketChannel? _channel;
  final _events = StreamController<CoachEvent>.broadcast();
  StreamSubscription<dynamic>? _subscription;
  bool _disposed = false;

  /// Stream of events from the agent.
  Stream<CoachEvent> get events => _events.stream;

  /// Connect to the coach WebSocket with a JWT token.
  Future<void> connect(String token) async {
    await _closeChannel();

    final uri = Uri.parse('$_wsBase/api/ws').replace(
      queryParameters: {'token': token},
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
    } catch (e) {
      _events.add(ConnectionError('Verbinding mislukt: $e'));
      return;
    }

    _subscription = _channel!.stream.listen(
      _onData,
      onError: (Object error) {
        if (!_disposed) {
          _events.add(ConnectionError('WebSocket fout: $error'));
        }
      },
      onDone: () {
        if (!_disposed) {
          _events.add(ConnectionClosed());
        }
      },
    );
  }

  /// Send a user message to the agent.
  void send(String message) {
    if (_channel == null) {
      _events.add(ConnectionError('Niet verbonden.'));
      return;
    }
    _channel!.sink.add(jsonEncode({'type': 'message', 'content': message}));
  }

  /// Start the intake flow.
  void startIntake() {
    if (_channel == null) {
      _events.add(ConnectionError('Niet verbonden.'));
      return;
    }
    _channel!.sink.add(jsonEncode({'type': 'start_intake'}));
  }

  /// Send a quick reply value.
  void sendQuickReply(String value) {
    if (_channel == null) {
      _events.add(ConnectionError('Niet verbonden.'));
      return;
    }
    _channel!.sink.add(jsonEncode({'type': 'quick_reply', 'value': value}));
  }

  /// Parse incoming JSON frames.
  void _onData(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'text_delta':
          _events.add(TextDelta(data['delta'] as String? ?? ''));
        case 'tool_use_start':
          _events.add(ToolUseStart(data['tool_name'] as String? ?? ''));
        case 'tool_result':
          _events.add(ToolResult(
            data['tool_name'] as String? ?? '',
            (data['result'] as Map<String, dynamic>?) ?? {},
          ));
        case 'quick_replies':
          final options = (data['options'] as List<dynamic>?)
              ?.map((o) => QuickReplyOption.fromJson(o as Map<String, dynamic>))
              .toList() ?? [];
          _events.add(QuickRepliesEvent(
            data['question_id'] as String? ?? '',
            options,
            data['input_type'] as String?,
          ));
        case 'plan_updated':
          _events.add(PlanUpdated(
            data['plan_id'] as String? ?? '',
            data['week'] as int? ?? 0,
          ));
        case 'message_end':
          _events.add(MessageEnd(
            data['input_tokens'] as int? ?? 0,
            data['output_tokens'] as int? ?? 0,
          ));
        case 'error':
          _events.add(ConnectionError(data['message'] as String? ?? 'Onbekende fout'));
        default:
          // Ignore unknown event types
          break;
      }
    } catch (e) {
      _events.add(ConnectionError('Bericht verwerken mislukt: $e'));
    }
  }

  Future<void> _closeChannel() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  /// Disconnect and clean up.
  Future<void> dispose() async {
    _disposed = true;
    await _closeChannel();
    await _events.close();
  }
}
