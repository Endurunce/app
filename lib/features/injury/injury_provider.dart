import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

// ── Models ─────────────────────────────────────────────────────────────────────

class SessionAdaptation {
  final String sessionId;
  final int weekNumber;
  final int weekday;
  final String sessionType;
  final String newType;
  final double targetKm;
  final double newKm;

  const SessionAdaptation({
    required this.sessionId,
    required this.weekNumber,
    required this.weekday,
    required this.sessionType,
    required this.newType,
    required this.targetKm,
    required this.newKm,
  });

  factory SessionAdaptation.fromJson(Map<String, dynamic> j) => SessionAdaptation(
    sessionId:   j['session_id'] as String,
    weekNumber:  j['week_number'] as int,
    weekday:     j['weekday'] as int,
    sessionType: j['session_type'] as String,
    newType:     j['new_type'] as String,
    targetKm:    (j['target_km'] as num).toDouble(),
    newKm:       (j['new_km'] as num).toDouble(),
  );
}

class InjuryReportResult {
  final String injuryId;
  final int recoveryWeeks;
  final List<SessionAdaptation> preview;

  const InjuryReportResult({
    required this.injuryId,
    required this.recoveryWeeks,
    required this.preview,
  });

  factory InjuryReportResult.fromJson(Map<String, dynamic> j) => InjuryReportResult(
    injuryId:      j['injury_id'] as String,
    recoveryWeeks: j['recovery_weeks'] as int,
    preview:       (j['preview'] as List)
        .map((e) => SessionAdaptation.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class Injury {
  final String id;
  final int severity;
  final bool canRun;
  final String status;
  final String reportedAt;
  final List<String> locations;
  final String? side;
  final String? painType;
  final String? painOnset;
  final int? durationDays;
  final String? resolvedAt;
  final String? description;

  const Injury({
    required this.id,
    required this.severity,
    required this.canRun,
    required this.status,
    required this.reportedAt,
    required this.locations,
    this.side,
    this.painType,
    this.painOnset,
    this.durationDays,
    this.resolvedAt,
    this.description,
  });

  bool get isResolved => status == 'resolved';

  factory Injury.fromJson(Map<String, dynamic> j) => Injury(
    id:           j['id'] as String,
    severity:     j['severity'] as int,
    canRun:       j['can_run'] as bool,
    status:       j['status'] as String,
    reportedAt:   j['reported_at'] as String,
    locations:    (j['locations'] as List).cast<String>(),
    side:         j['side'] as String?,
    painType:     j['pain_type'] as String?,
    painOnset:    j['pain_onset'] as String?,
    durationDays: j['duration_days'] as int?,
    resolvedAt:   j['resolved_at'] as String?,
    description:  j['description'] as String?,
  );
}

// ── Active injuries notifier ───────────────────────────────────────────────────

class InjuryNotifier extends Notifier<List<Injury>> {
  @override
  List<Injury> build() => [];

  Future<void> load() async {
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/api/injuries') as List;
      state = data.map((e) => Injury.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, stack) {
      developer.log('Failed to load injuries', name: 'InjuryProvider', error: e, stackTrace: stack);
      state = [];
    }
  }

  /// Save the injury and return a preview of plan changes (plan not modified yet).
  Future<InjuryReportResult?> report({
    required List<String> locations,
    required int severity,
    required bool canWalk,
    required bool canRun,
    String? side,
    String? painType,
    String? painOnset,
    int? durationDays,
    String? description,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.post('/api/injuries', {
        'locations':    locations,
        'severity':     severity,
        'can_walk':     canWalk,
        'can_run':      canRun,
        if (side != null)         'side':          side,
        if (painType != null)     'pain_type':     painType,
        if (painOnset != null)    'pain_onset':    painOnset,
        if (durationDays != null) 'duration_days': durationDays,
        if (description != null)  'description':   description,
      });
      await load();
      return InjuryReportResult.fromJson(resp as Map<String, dynamic>);
    } catch (e, stack) {
      developer.log('Failed to report injury', name: 'InjuryProvider', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Apply the plan adaptation for an injury the user approved.
  Future<bool> applyAdaptation(String injuryId) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.patch('/api/injuries/$injuryId/adapt');
      return true;
    } catch (e, stack) {
      developer.log('Failed to apply adaptation', name: 'InjuryProvider', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> resolve(String injuryId) async {
    final client = ref.read(apiClientProvider);
    await client.patch('/api/injuries/$injuryId/resolve');
    await load();
  }
}

final injuryProvider = NotifierProvider<InjuryNotifier, List<Injury>>(InjuryNotifier.new);

// ── Injury history notifier ────────────────────────────────────────────────────

class InjuryHistoryState {
  final List<Injury> items;
  final bool loading;

  const InjuryHistoryState({this.items = const [], this.loading = false});

  InjuryHistoryState copyWith({List<Injury>? items, bool? loading}) =>
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
        items: data.map((e) => Injury.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e, stack) {
      developer.log('Failed to load injury history', name: 'InjuryProvider', error: e, stackTrace: stack);
      state = state.copyWith(loading: false);
    }
  }
}

final injuryHistoryProvider =
    NotifierProvider<InjuryHistoryNotifier, InjuryHistoryState>(InjuryHistoryNotifier.new);
