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
    id:                  j['id'].toString(),
    name:                j['name'] as String,
    type:                j['type'] as String,
    distanceM:           (j['distance'] as num).toDouble(),
    movingTimeSec:       j['moving_time'] as int,
    startDate:           DateTime.parse(j['start_date'] as String),
    averageHeartrate:    (j['average_heartrate'] as num?)?.toDouble(),
    totalElevationGain:  (j['total_elevation_gain'] as num?)?.toDouble(),
  );
}

class StravaState {
  final bool connected;
  final String? displayName;
  final String? avatarUrl;
  final List<StravaActivity> activities;
  final bool loading;
  final String? error;
  final bool connecting;

  const StravaState({
    this.connected = false,
    this.displayName,
    this.avatarUrl,
    this.activities = const [],
    this.loading = false,
    this.error,
    this.connecting = false,
  });

  StravaState copyWith({
    bool? connected,
    String? displayName,
    String? avatarUrl,
    List<StravaActivity>? activities,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? connecting,
  }) => StravaState(
    connected:   connected   ?? this.connected,
    displayName: displayName ?? this.displayName,
    avatarUrl:   avatarUrl   ?? this.avatarUrl,
    activities:  activities  ?? this.activities,
    loading:     loading     ?? this.loading,
    error:       clearError ? null : (error ?? this.error),
    connecting:  connecting  ?? this.connecting,
  );
}

class StravaNotifier extends Notifier<StravaState> {
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

  Future<void> connectWithCode({
    required String clientId,
    required String clientSecret,
    required String code,
  }) async {
    state = state.copyWith(connecting: true, clearError: true);
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.post('/api/strava/exchange-code', {
        'client_id':     clientId,
        'client_secret': clientSecret,
        'code':          code,
        'redirect_uri':  'http://localhost',
      });
      final data = resp as Map<String, dynamic>;
      state = state.copyWith(
        connecting:  false,
        connected:   true,
        displayName: data['display_name'] as String?,
        avatarUrl:   data['avatar_url'] as String?,
      );
      await loadActivities();
    } catch (e) {
      state = state.copyWith(
        connecting: false,
        error: 'Verbinden mislukt. Controleer je codes en probeer opnieuw.',
      );
    }
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

  void openStravaOAuth(String clientId) {
    final url = 'https://www.strava.com/oauth/authorize'
        '?client_id=$clientId'
        '&redirect_uri=${Uri.encodeComponent('http://localhost')}'
        '&response_type=code'
        '&approval_prompt=auto'
        '&scope=activity:read_all';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

final stravaProvider = NotifierProvider<StravaNotifier, StravaState>(StravaNotifier.new);
