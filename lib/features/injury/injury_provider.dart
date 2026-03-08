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

class InjuryNotifier extends Notifier<List<Injury>> {
  @override
  List<Injury> build() => [];

  Future<void> load() async {
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/api/injuries') as List;
      state = data.map((e) => Injury.fromJson(e)).toList();
    } catch (_) {
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
    } catch (e) {
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
