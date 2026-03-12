import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class Injury {
  final String id;
  final int severity;
  final bool canRun;
  final String recoveryStatus;
  final String reportedAt;
  final String? description;

  const Injury({
    required this.id,
    required this.severity,
    required this.canRun,
    required this.recoveryStatus,
    required this.reportedAt,
    this.description,
  });

  factory Injury.fromJson(Map<String, dynamic> j) => Injury(
    id:             j['id'] as String,
    severity:       j['severity'] as int,
    canRun:         j['can_run'] as bool,
    recoveryStatus: j['recovery_status'] as String,
    reportedAt:     j['reported_at'] as String,
    description:    j['description'] as String?,
  );
}

class InjuryHistoryItem {
  final String id;
  final int severity;
  final bool canRun;
  final String recoveryStatus;
  final String reportedAt;
  final String? resolvedAt;
  final List<String> locations;
  final String? description;

  const InjuryHistoryItem({
    required this.id,
    required this.severity,
    required this.canRun,
    required this.recoveryStatus,
    required this.reportedAt,
    required this.locations,
    this.resolvedAt,
    this.description,
  });

  bool get isResolved => recoveryStatus == 'resolved';

  factory InjuryHistoryItem.fromJson(Map<String, dynamic> j) => InjuryHistoryItem(
    id:             j['id'] as String,
    severity:       j['severity'] as int,
    canRun:         j['can_run'] as bool,
    recoveryStatus: j['recovery_status'] as String,
    reportedAt:     j['reported_at'] as String,
    resolvedAt:     j['resolved_at'] as String?,
    locations:      (j['locations'] as List).cast<String>(),
    description:    j['description'] as String?,
  );
}

// ── Active injuries state ──────────────────────────────────────────────────────

class InjuryNotifier extends Notifier<List<Injury>> {
  @override
  List<Injury> build() => [];

  Future<void> load() async {
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/api/injuries') as List;
      state = data.map((e) => Injury.fromJson(e)).toList();
    } catch (e, stack) {
      developer.log('Failed to load injuries', name: 'InjuryProvider', error: e, stackTrace: stack);
      state = [];
    }
  }

  Future<String?> report({
    required List<String> locations,
    required int severity,
    required bool canWalk,
    required bool canRun,
    String? description,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.post('/api/injuries', {
        'locations':   locations,
        'severity':    severity,
        'can_walk':    canWalk,
        'can_run':     canRun,
        if (description != null) 'description': description,
      });
      await load();
      final recoveryWeeks = resp['recovery_weeks'] as int;
      return 'Blessure geregistreerd. Geschat herstel: $recoveryWeeks week(en). Je plan is aangepast.';
    } catch (e, stack) {
      developer.log('Failed to report injury', name: 'InjuryProvider', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<void> resolve(String injuryId) async {
    final client = ref.read(apiClientProvider);
    await client.patch('/api/injuries/$injuryId/resolve');
    await load();
  }
}

final injuryProvider = NotifierProvider<InjuryNotifier, List<Injury>>(InjuryNotifier.new);

// ── Injury history state ───────────────────────────────────────────────────────

class InjuryHistoryState {
  final List<InjuryHistoryItem> items;
  final bool loading;

  const InjuryHistoryState({this.items = const [], this.loading = false});

  InjuryHistoryState copyWith({List<InjuryHistoryItem>? items, bool? loading}) =>
      InjuryHistoryState(
        items:   items   ?? this.items,
        loading: loading ?? this.loading,
      );
}

class InjuryHistoryNotifier extends Notifier<InjuryHistoryState> {
  @override
  InjuryHistoryState build() => const InjuryHistoryState();

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/api/injuries/history') as List;
      state = state.copyWith(
        loading: false,
        items: data.map((e) => InjuryHistoryItem.fromJson(e)).toList(),
      );
    } catch (e, stack) {
      developer.log('Failed to load injury history', name: 'InjuryProvider', error: e, stackTrace: stack);
      state = state.copyWith(loading: false);
    }
  }
}

final injuryHistoryProvider =
    NotifierProvider<InjuryHistoryNotifier, InjuryHistoryState>(InjuryHistoryNotifier.new);
