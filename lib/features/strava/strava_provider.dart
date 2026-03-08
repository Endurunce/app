import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';

class StravaActivity {
  final String id;
  final String name;
  final String type;
  final double distanceM;
  final int movingTimeSec;
  final DateTime startDate;
  final double? averageHeartrate;
  final double? totalElevationGain;

  double get distanceKm => distanceM / 1000;

  String get durationFormatted {
    final mins = movingTimeSec ~/ 60;
    return mins >= 60 ? '${mins ~/ 60}u ${mins % 60}m' : '${mins}m';
  }

  const StravaActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceM,
    required this.movingTimeSec,
    required this.startDate,
    this.averageHeartrate,
    this.totalElevationGain,
  });

  factory StravaActivity.fromJson(Map<String, dynamic> j) => StravaActivity(
    id:                 j['id'].toString(),
    name:               j['name'] as String,
    type:               j['type'] as String,
    distanceM:          (j['distance'] as num).toDouble(),
    movingTimeSec:      j['moving_time'] as int,
    startDate:          DateTime.parse(j['start_date'] as String),
    averageHeartrate:   (j['average_heartrate'] as num?)?.toDouble(),
    totalElevationGain: (j['total_elevation_gain'] as num?)?.toDouble(),
  );
}

class StravaState {
  final bool connected;
  final String? displayName;
  final String? avatarUrl;
  final List<StravaActivity> activities;
  final bool loading;
  final bool waitingForCallback; // browser open, polling
  final String? error;

  const StravaState({
    this.connected = false,
    this.displayName,
    this.avatarUrl,
    this.activities = const [],
    this.loading = false,
    this.waitingForCallback = false,
    this.error,
  });

  StravaState copyWith({
    bool? connected,
    String? displayName,
    String? avatarUrl,
    List<StravaActivity>? activities,
    bool? loading,
    bool? waitingForCallback,
    String? error,
    bool clearError = false,
  }) => StravaState(
    connected:           connected           ?? this.connected,
    displayName:         displayName         ?? this.displayName,
    avatarUrl:           avatarUrl           ?? this.avatarUrl,
    activities:          activities          ?? this.activities,
    loading:             loading             ?? this.loading,
    waitingForCallback:  waitingForCallback  ?? this.waitingForCallback,
    error:               clearError ? null : (error ?? this.error),
  );
}

class StravaNotifier extends Notifier<StravaState> {
  Timer? _pollTimer;

  @override
  StravaState build() => const StravaState();

  Future<void> checkStatus() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/api/strava/status') as Map<String, dynamic>;
      final connected = data['connected'] as bool;
      state = state.copyWith(
        loading:     false,
        connected:   connected,
        displayName: data['display_name'] as String?,
        avatarUrl:   data['avatar_url'] as String?,
      );
      if (connected) await loadActivities();
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  /// Haalt de OAuth-URL op van de backend, opent de browser en begint te pollen.
  Future<void> startConnect() async {
    state = state.copyWith(clearError: true, waitingForCallback: true);
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/api/strava/connect') as Map<String, dynamic>;
      final authUrl = data['auth_url'] as String;

      await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);

      _startPolling();
    } catch (e) {
      state = state.copyWith(
        waitingForCallback: false,
        error: 'Verbinden met Strava mislukt. Probeer opnieuw.',
      );
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final client = ref.read(apiClientProvider);
        final data = await client.get('/api/strava/status') as Map<String, dynamic>;
        if (data['connected'] == true) {
          _pollTimer?.cancel();
          state = state.copyWith(
            waitingForCallback: false,
            connected:   true,
            displayName: data['display_name'] as String?,
            avatarUrl:   data['avatar_url'] as String?,
          );
          await loadActivities();
        }
      } catch (_) {}
    });
  }

  void cancelConnect() {
    _pollTimer?.cancel();
    state = state.copyWith(waitingForCallback: false, clearError: true);
  }

  Future<void> loadActivities() async {
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/api/strava/activities?per_page=50') as List;
      final acts = data
          .map((e) => StravaActivity.fromJson(e as Map<String, dynamic>))
          .where((a) => ['Run', 'TrailRun', 'Hike', 'Walk'].contains(a.type))
          .toList();
      state = state.copyWith(activities: acts);
    } catch (_) {}
  }
}

final stravaProvider = NotifierProvider<StravaNotifier, StravaState>(StravaNotifier.new);
