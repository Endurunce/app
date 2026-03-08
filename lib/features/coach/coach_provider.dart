import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class CoachMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime createdAt;

  const CoachMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory CoachMessage.fromJson(Map<String, dynamic> j) => CoachMessage(
    id:        j['id'] as String,
    role:      j['role'] as String,
    content:   j['content'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class CoachState {
  final List<CoachMessage> messages;
  final bool loading;
  final bool sending;
  final String? error;

  const CoachState({
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.error,
  });

  CoachState copyWith({
    List<CoachMessage>? messages,
    bool? loading,
    bool? sending,
    String? error,
    bool clearError = false,
  }) => CoachState(
    messages: messages ?? this.messages,
    loading:  loading  ?? this.loading,
    sending:  sending  ?? this.sending,
    error:    clearError ? null : (error ?? this.error),
  );
}

class CoachNotifier extends Notifier<CoachState> {
  @override
  CoachState build() => const CoachState();

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/api/coach') as List;
      state = state.copyWith(
        loading:  false,
        messages: data.map((e) => CoachMessage.fromJson(e)).toList(),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Kon berichten niet laden.');
    }
  }

  Future<void> send(String content) async {
    final text = content.trim();
    if (text.isEmpty) return;

    // Optimistically add user message
    final optimistic = CoachMessage(
      id: 'pending',
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, optimistic],
      sending: true,
      clearError: true,
    );

    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.post('/api/coach', {'content': text});
      final assistantMsg = CoachMessage.fromJson(resp);
      // Append the assistant response; the optimistic user message stays
      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        sending: false,
      );
    } catch (e) {
      String errorMsg = 'Bericht versturen mislukt. Probeer opnieuw.';
      if (e is DioException) {
        final code   = e.response?.statusCode;
        final body   = e.response?.data;
        final detail = (body is Map) ? body['error'] as String? : null;
        if (code == 400 && detail != null) errorMsg = detail;
        if (code == 429) errorMsg = detail ?? 'Je hebt het berichtlimiet bereikt. Probeer later opnieuw.';
      }
      // Remove the optimistic user message on failure
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != 'pending').toList(),
        sending: false,
        error: errorMsg,
      );
    }
  }
}

final coachProvider = NotifierProvider<CoachNotifier, CoachState>(CoachNotifier.new);
