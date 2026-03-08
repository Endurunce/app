import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class Day {
  final int weekday;
  final String sessionType;
  final double targetKm;
  final double? adjustedKm;
  final bool completed;
  final String? notes;

  const Day({
    required this.weekday,
    required this.sessionType,
    required this.targetKm,
    this.adjustedKm,
    this.completed = false,
    this.notes,
  });

  double get effectiveKm => adjustedKm ?? targetKm;

  factory Day.fromJson(Map<String, dynamic> j) => Day(
    weekday:     j['weekday'] as int,
    sessionType: j['session_type'] as String,
    targetKm:    (j['target_km'] as num).toDouble(),
    adjustedKm:  (j['adjusted_km'] as num?)?.toDouble(),
    completed:   j['completed'] as bool? ?? false,
    notes:       j['notes'] as String?,
  );
}

class Week {
  final int weekNumber;
  final String phase;
  final bool isRecovery;
  final double targetKm;
  final List<Day> days;

  const Week({
    required this.weekNumber,
    required this.phase,
    required this.isRecovery,
    required this.targetKm,
    required this.days,
  });

  String get phaseLabel => switch (phase) {
    'build_one' => 'Opbouw I',
    'build_two' => 'Opbouw II',
    'peak'      => 'Piek',
    'taper'     => 'Tapering',
    _           => phase,
  };

  List<Day> get activeDays => days.where((d) => d.sessionType != 'rest').toList();
  int get completedCount  => days.where((d) => d.completed).length;

  factory Week.fromJson(Map<String, dynamic> j) => Week(
    weekNumber: j['week_number'] as int,
    phase:      j['phase'] as String,
    isRecovery: j['is_recovery'] as bool? ?? false,
    targetKm:   (j['target_km'] as num).toDouble(),
    days:       (j['days'] as List).map((d) => Day.fromJson(d)).toList(),
  );
}

class TrainingPlan {
  final String id;
  final List<Week> weeks;

  const TrainingPlan({required this.id, required this.weeks});

  factory TrainingPlan.fromJson(Map<String, dynamic> j) => TrainingPlan(
    id:    j['id'] as String,
    weeks: (j['weeks'] as List).map((w) => Week.fromJson(w)).toList(),
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────

class PlanState {
  final TrainingPlan? plan;
  final bool loading;
  final String? error;

  const PlanState({this.plan, this.loading = false, this.error});

  PlanState copyWith({TrainingPlan? plan, bool? loading, String? error, bool clearError = false}) =>
      PlanState(
        plan:    plan    ?? this.plan,
        loading: loading ?? this.loading,
        error:   clearError ? null : (error ?? this.error),
      );
}

class PlanNotifier extends Notifier<PlanState> {
  @override
  PlanState build() => const PlanState();

  Future<void> loadActivePlan() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/api/plans');
      state = state.copyWith(loading: false, plan: TrainingPlan.fromJson(data));
    } catch (e) {
      final msg = e.toString().contains('404')
          ? 'no_plan'
          : 'Kon plan niet laden.';
      state = state.copyWith(loading: false, error: msg);
    }
  }

  Future<void> completeDay({
    required String planId,
    required int weekNumber,
    required int weekday,
    required int feeling,
    required bool pain,
    String? notes,
    double? actualKm,
  }) async {
    final client = ref.read(apiClientProvider);
    await client.post(
      '/api/plans/$planId/weeks/$weekNumber/days/$weekday/complete',
      {
        'feeling':   feeling,
        'pain':      pain,
        if (notes != null)    'notes': notes,
        if (actualKm != null) 'actual_km': actualKm,
      },
    );
    await loadActivePlan(); // refresh
  }
}

final planProvider = NotifierProvider<PlanNotifier, PlanState>(PlanNotifier.new);
