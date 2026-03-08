import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class UserProfile {
  final String name;
  final int age;
  final String gender;
  final dynamic raceGoal; // raw JSON
  final String? raceDate;
  final String terrain;
  final double weeklyKm;
  final String runningYears;

  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.raceGoal,
    required this.raceDate,
    required this.terrain,
    required this.weeklyKm,
    required this.runningYears,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name:         j['name'] as String,
    age:          (j['age'] as num).toInt(),
    gender:       j['gender'] as String,
    raceGoal:     j['race_goal'],
    raceDate:     j['race_date'] as String?,
    terrain:      j['terrain'] as String,
    weeklyKm:     (j['weekly_km'] as num).toDouble(),
    runningYears: j['running_years'] as String,
  );

  String get raceGoalLabel {
    if (raceGoal is String) {
      return switch (raceGoal as String) {
        'marathon'       => 'Marathon',
        'half_marathon'  => 'Halve marathon',
        'ten_km'         => '10 km',
        'five_km'        => '5 km',
        'ultra'          => 'Ultra',
        _                => raceGoal as String,
      };
    }
    if (raceGoal is Map) {
      final custom = (raceGoal as Map)['custom'];
      if (custom != null) {
        final km = (custom as Map)['distance_km'];
        return '$km km (eigen doel)';
      }
    }
    return 'Onbekend';
  }

  String get raceGoalEmoji {
    if (raceGoal is String) {
      return switch (raceGoal as String) {
        'marathon'      => '🏆',
        'half_marathon' => '🥈',
        'ten_km'        => '🎯',
        'five_km'       => '⚡',
        'ultra'         => '🦅',
        _               => '🏃',
      };
    }
    return '🏃';
  }

  String get genderLabel => switch (gender) {
    'male'   => 'Man',
    'female' => 'Vrouw',
    _        => 'Anders',
  };

  String get runningYearsLabel => switch (runningYears) {
    'less_than_two_years'  => '< 2 jaar',
    'two_to_five_years'    => '2–5 jaar',
    'five_to_ten_years'    => '5–10 jaar',
    'more_than_ten_years'  => '10+ jaar',
    _                      => runningYears,
  };

  String get terrainLabel => switch (terrain) {
    'road'  => 'Weg',
    'trail' => 'Trail',
    _       => terrain,
  };
}

class ProfileState {
  final UserProfile? profile;
  final bool loading;
  final String? error;

  const ProfileState({this.profile, this.loading = false, this.error});

  ProfileState copyWith({UserProfile? profile, bool? loading, String? error}) =>
      ProfileState(
        profile: profile ?? this.profile,
        loading: loading ?? this.loading,
        error:   error   ?? this.error,
      );
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/api/profiles/me');
      if (data == null) {
        state = state.copyWith(loading: false);
        return;
      }
      state = state.copyWith(
        loading: false,
        profile: UserProfile.fromJson(data as Map<String, dynamic>),
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<bool> update({
    String? name,
    int? age,
    String? gender,
    double? weeklyKm,
    String? runningYears,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        if (name != null) 'name': name,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (weeklyKm != null) 'weekly_km': weeklyKm,
        if (runningYears != null) 'running_years': runningYears,
      };
      await client.patch('/api/profiles/me', data: body);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
