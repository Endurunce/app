import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_client.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/plan/plan_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/age.dart';
import 'intake_helpers.dart';
import 'step_experience.dart';
import 'step_health.dart';
import 'step_heartrate.dart';
import 'step_performance.dart';
import 'step_personal.dart';
import 'step_race_goal.dart';
import 'step_training_days.dart';

class IntakeScreen extends ConsumerStatefulWidget {
  final bool showWelcome;
  const IntakeScreen({super.key, this.showWelcome = false});

  @override
  ConsumerState<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends ConsumerState<IntakeScreen> {
  int _step = 1;
  int _fromStep = 1;
  static const _totalSteps = 7;
  bool _submitting = false;
  bool _step1Prefilled = false;
  bool _showingWelcome = false;

  // Step 1
  final _nameCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;

  // Step 2
  String? _runningYears;
  double _weeklyKm = 0;
  final String _previousUltra = 'none';

  // Step 3
  Duration? _time10k;
  Duration? _timeHalf;
  Duration? _timeMarathon;

  // Step 4
  Duration? _raceTimeGoal;
  String? _raceGoal;
  double? _raceGoalCustomKm;
  DateTime? _raceDate;
  String? _terrain;

  // Step 5
  final Set<int> _trainingDays = {};
  final Map<int, int> _dayDurations = {};
  int? _longRunDay;
  bool _addStrength = false;
  final Set<int> _strengthDays = {};

  // Step 6
  bool _hrAuto = true;
  final _maxHrCtrl = TextEditingController();
  final _restHrCtrl = TextEditingController(text: '55');
  final List<TextEditingController> _zoneLoCtrls =
      List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _zoneHiCtrls =
      List.generate(5, (_) => TextEditingController());

  // Step 7
  String? _sleep;
  final _complaintsCtrl = TextEditingController();
  final Set<String> _previousInjuries = {};

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    if (auth.displayName != null) _nameCtrl.text = auth.displayName!;
    if (auth.dateOfBirth != null) _dateOfBirth = auth.dateOfBirth;
    if (auth.gender != null) _gender = auth.gender;

    if (_nameCtrl.text.isNotEmpty && _dateOfBirth != null && _gender != null) {
      _step1Prefilled = true;
      _step = 2;
      _fromStep = 2;
    }

    if (widget.showWelcome) _showingWelcome = true;
    _recalcZones(forceUpdate: true);
  }

  void _recalcZones({bool forceUpdate = false}) {
    final dob = _dateOfBirth ?? DateTime(DateTime.now().year - 30);
    final age = calculateAge(dob);
    final maxHr =
        _hrAuto ? (220 - age) : (int.tryParse(_maxHrCtrl.text) ?? (220 - age));
    final restHr = int.tryParse(_restHrCtrl.text) ?? 55;
    final hrr = (maxHr - restHr).toDouble();
    int kv(double f) => (restHr + hrr * f).round();
    final lows = [kv(0.50), kv(0.60), kv(0.70), kv(0.80), kv(0.90)];
    final highs = [kv(0.60), kv(0.70), kv(0.80), kv(0.90), maxHr];
    for (int i = 0; i < 5; i++) {
      if (forceUpdate || _zoneLoCtrls[i].text.isEmpty) {
        _zoneLoCtrls[i].text = lows[i].toString();
      }
      if (forceUpdate || _zoneHiCtrls[i].text.isEmpty) {
        _zoneHiCtrls[i].text = highs[i].toString();
      }
    }
  }

  int get _displayStep => _step1Prefilled ? _step - 1 : _step;
  int get _displayTotal => _step1Prefilled ? _totalSteps - 1 : _totalSteps;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxHrCtrl.dispose();
    _restHrCtrl.dispose();
    for (final c in [..._zoneLoCtrls, ..._zoneHiCtrls]) {
      c.dispose();
    }
    _complaintsCtrl.dispose();
    super.dispose();
  }

  bool get _isUnderSixteen {
    if (_dateOfBirth == null) return false;
    return calculateAge(_dateOfBirth!) < 16;
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Selecteer je geboortedatum',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  bool get _canNext {
    switch (_step) {
      case 1:
        return _nameCtrl.text.isNotEmpty &&
            _dateOfBirth != null &&
            !_isUnderSixteen &&
            _gender != null;
      case 2:
        return _runningYears != null;
      case 3:
        return true;
      case 4:
        return _raceGoal != null && _raceDate != null && _terrain != null;
      case 5:
        return _trainingDays.length >= 2 &&
            _longRunDay != null &&
            _trainingDays.contains(_longRunDay);
      case 6:
        return true;
      case 7:
        return _sleep != null;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_step < _totalSteps) {
      setState(() {
        _fromStep = _step;
        _step++;
      });
    } else {
      _submit();
    }
  }

  void _prevStep() {
    final minStep = _step1Prefilled ? 2 : 1;
    if (_step > minStep) {
      setState(() {
        _fromStep = _step;
        _step--;
      });
    } else if (widget.showWelcome) {
      setState(() => _showingWelcome = true);
    }
  }

  void _skipStep() {
    if (_step < _totalSteps) {
      setState(() {
        _fromStep = _step;
        _step++;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final client = ref.read(apiClientProvider);
      final dob = _dateOfBirth ?? DateTime(1990);
      final age = calculateAge(dob);

      final profile = {
        'name': _nameCtrl.text.trim(),
        'date_of_birth':
            '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
        'gender': _gender ?? 'other',
        'running_years': _runningYears ?? 'two_to_five_years',
        'weekly_km': _weeklyKm,
        'previous_ultra': _previousUltra,
        'time_10k': formatDuration(_time10k),
        'time_half_marathon': formatDuration(_timeHalf),
        'time_marathon': formatDuration(_timeMarathon),
        'race_goal': _raceGoalCustomKm != null
            ? {
                'custom': {'distance_km': _raceGoalCustomKm}
              }
            : _raceGoal,
        'race_time_goal': formatDuration(_raceTimeGoal),
        'race_date': _raceDate?.toIso8601String().split('T')[0],
        'terrain': _terrain ?? 'road',
        'training_days': _trainingDays.toList()..sort(),
        'strength_days': _strengthDays.toList()..sort(),
        'max_duration_per_day': _trainingDays
            .map((d) => {
                  'day': d,
                  'max_minutes': _dayDurations[d] ?? 60,
                })
            .toList(),
        'long_run_day': _longRunDay,
        'max_hr': _hrAuto
            ? (220 - age)
            : (_maxHrCtrl.text.isNotEmpty ? int.tryParse(_maxHrCtrl.text) : null),
        'rest_hr': int.tryParse(_restHrCtrl.text) ?? 55,
        'hr_zones': [
          for (int i = 0; i < 5; i++)
            {
              'num': i + 1,
              'name': [
                'Herstel',
                'Aerobe basis',
                'Aerobe drempel',
                'Anaerobe drempel',
                'VO₂max'
              ][i],
              'lo': int.tryParse(_zoneLoCtrls[i].text) ?? 0,
              'hi': int.tryParse(_zoneHiCtrls[i].text) ?? 0,
              'color': [
                '#7bc67e',
                '#5a7a52',
                '#c49a5a',
                '#b85c3a',
                '#c0392b'
              ][i],
              'description': [
                'Actief herstel, wandelen',
                'Lange duurlopen, praattempo',
                'Tempoduurloop, comfortabel',
                'Tempolopen, lactaatdrempel',
                'Intervaltraining, max inspanning'
              ][i],
            }
        ],
        'sleep_hours': _sleep ?? 'seven_to_eight',
        'complaints':
            _complaintsCtrl.text.isNotEmpty ? _complaintsCtrl.text : null,
        'previous_injuries': _previousInjuries.toList(),
      };

      await client.post('/api/plans/generate', {'profile': profile});
      await ref.read(planProvider.notifier).loadActivePlan();
      if (mounted) context.go('/plan');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showingWelcome) return _buildWelcomePage();

    final isSkippable = _step == 3 || _step == 6;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Jouw plan opmaken'),
        leading: (_step1Prefilled ? _step > 2 : _step > 1) || widget.showWelcome
            ? IconButton(
                icon: const Icon(Icons.arrow_back), onPressed: _prevStep)
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.go('/plan'),
                tooltip: 'Sluiten',
              ),
        actions: [
          if (isSkippable)
            TextButton(
              onPressed: _skipStep,
              child: const Text('Overslaan'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(children: [
              Row(
                children: List.generate(
                    _displayTotal,
                    (i) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              color: i < _displayStep
                                  ? AppColors.brand
                                  : AppColors.outline,
                            ),
                          ),
                        )),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Stap $_displayStep van $_displayTotal',
                    style: Theme.of(context).textTheme.labelSmall),
              ),
            ]),
          ),

          // Step content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final goingForward = _step >= _fromStep;
                final offset = Tween<Offset>(
                  begin: Offset(goingForward ? 0.06 : -0.06, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: SingleChildScrollView(
                key: ValueKey(_step),
                padding: const EdgeInsets.all(20),
                child: _buildStep(),
              ),
            ),
          ),

          // Bottom bar
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 16),
              child: FilledButton.icon(
                onPressed: (_canNext && !_submitting) ? _nextStep : null,
                icon: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Icon(
                        _step == _totalSteps
                            ? Icons.rocket_launch_outlined
                            : Icons.arrow_forward,
                        size: 18),
                label: Text(
                    _step == _totalSteps ? 'Plan aanmaken' : 'Volgende'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    final name = ref.read(authProvider).displayName;
    final greeting =
        (name != null && name.isNotEmpty) ? 'Welkom, $name!' : 'Welkom bij Endurance!';

    const features = [
      ('🎯', 'Doelgericht plan', 'Afgestemd op jouw race, niveau en tijdslot'),
      ('📅', 'Wekelijks schema', 'Sessies verdeeld over jouw eigen trainingsdagen'),
      ('💬', 'AI-coach', 'Persoonlijk advies en begeleiding tijdens je training'),
      ('📈', 'Slim opbouwen', 'Progressieve belasting richting je piekweek'),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.brand, AppColors.brandDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: .35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🏃', style: TextStyle(fontSize: 42)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                greeting,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'We gaan nu een persoonlijk trainingsplan voor je opmaken.\nDit duurt ongeveer 2 minuten.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.onSurface, height: 1.55),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  children: features.map((f) {
                    final isLast = f == features.last;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(f.$1,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f.$2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.onBg,
                                    )),
                                const SizedBox(height: 2),
                                Text(f.$3,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                      height: 1.4,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Spacer(flex: 3),
              FilledButton.icon(
                onPressed: () => setState(() => _showingWelcome = false),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Plan opmaken'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/plan'),
                child: const Text('Later instellen'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      1 => StepPersonal(
          nameCtrl: _nameCtrl,
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          onPickDob: _pickDateOfBirth,
          onGenderChanged: (v) => setState(() => _gender = v),
          onChanged: () => setState(() {}),
        ),
      2 => StepExperience(
          runningYears: _runningYears,
          weeklyKm: _weeklyKm,
          onRunningYearsChanged: (v) => setState(() => _runningYears = v),
          onWeeklyKmChanged: (v) => setState(() => _weeklyKm = v),
        ),
      3 => StepPerformance(
          time10k: _time10k,
          timeHalf: _timeHalf,
          timeMarathon: _timeMarathon,
          onTime10kChanged: (d) => setState(() => _time10k = d),
          onTimeHalfChanged: (d) => setState(() => _timeHalf = d),
          onTimeMarathonChanged: (d) => setState(() => _timeMarathon = d),
        ),
      4 => StepRaceGoal(
          raceGoal: _raceGoal,
          raceGoalCustomKm: _raceGoalCustomKm,
          raceDate: _raceDate,
          terrain: _terrain,
          raceTimeGoal: _raceTimeGoal,
          weeklyKm: _weeklyKm,
          onRaceGoalChanged: (v, km) =>
              setState(() { _raceGoal = v; _raceGoalCustomKm = km; }),
          onCustomKmChanged: (v) => setState(() => _raceGoalCustomKm = v),
          onRaceDateChanged: (v) { if (v != null) setState(() => _raceDate = v); },
          onTerrainChanged: (v) => setState(() => _terrain = v),
          onRaceTimeGoalChanged: (d) => setState(() => _raceTimeGoal = d),
        ),
      5 => StepTrainingDays(
          trainingDays: _trainingDays,
          dayDurations: _dayDurations,
          longRunDay: _longRunDay,
          addStrength: _addStrength,
          strengthDays: _strengthDays,
          onToggleTrainingDay: (i) => setState(() {
            if (_trainingDays.contains(i)) {
              _trainingDays.remove(i);
              _dayDurations.remove(i);
              if (_longRunDay == i) _longRunDay = null;
            } else {
              _trainingDays.add(i);
              _dayDurations[i] = 60;
            }
          }),
          onDayDurationChanged: (d, v) => setState(() => _dayDurations[d] = v),
          onLongRunDayChanged: (v) => setState(() {
            _longRunDay = v;
            if (v != null) _dayDurations[v] = 180;
          }),
          onAddStrengthChanged: (v) => setState(() {
            _addStrength = v;
            if (!v) _strengthDays.clear();
          }),
          onToggleStrengthDay: (i) => setState(() {
            if (_strengthDays.contains(i)) {
              _strengthDays.remove(i);
            } else {
              _strengthDays.add(i);
            }
          }),
        ),
      6 => StepHeartrate(
          dateOfBirth: _dateOfBirth,
          hrAuto: _hrAuto,
          maxHrCtrl: _maxHrCtrl,
          restHrCtrl: _restHrCtrl,
          zoneLoCtrls: _zoneLoCtrls,
          zoneHiCtrls: _zoneHiCtrls,
          onHrAutoChanged: (v) => setState(() {
            _hrAuto = v;
            if (v) _recalcZones(forceUpdate: true);
          }),
          onRecalcZones: () => setState(() => _recalcZones(forceUpdate: true)),
          onChanged: () => setState(() {}),
        ),
      7 => StepHealth(
          sleep: _sleep,
          complaintsCtrl: _complaintsCtrl,
          previousInjuries: _previousInjuries,
          onSleepChanged: (v) => setState(() => _sleep = v),
          onToggleInjury: (loc) => setState(() {
            if (_previousInjuries.contains(loc)) {
              _previousInjuries.remove(loc);
            } else {
              _previousInjuries.add(loc);
            }
          }),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
