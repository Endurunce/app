import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/plan/plan_provider.dart';
import '../../shared/theme/app_theme.dart';

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
  bool _step1Prefilled = false; // stap 1 overslaan als alles al bekend is
  bool _showingWelcome = false; // welkomstslide voor nieuwe accounts

  // Step 1
  final _nameCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;

  // Step 2
  String? _runningYears;
  double  _weeklyKm    = 0;
  String  _previousUltra = 'none';

  // Step 3 (optional) — duraties als nullable Duration
  Duration? _time10k;
  Duration? _timeHalf;
  Duration? _timeMarathon;

  // Step 4 — tijdsdoelstelling als Duration
  Duration? _raceTimeGoal;

  // Step 4
  String? _raceGoal;
  double? _raceGoalCustomKm;
  DateTime? _raceDate;
  String? _terrain;

  // Step 5
  final Set<int> _trainingDays  = {};
  final Map<int, int> _dayDurations = {};
  int? _longRunDay;
  bool _addStrength = false;
  final Set<int> _strengthDays  = {};

  // Step 6 (optional)
  bool _hrAuto = true;
  final _maxHrCtrl  = TextEditingController();
  final _restHrCtrl = TextEditingController(text: '55');
  // Bewerkbare hartslagzones (lo/hi per zone)
  final List<TextEditingController> _zoneLoCtrls = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _zoneHiCtrls = List.generate(5, (_) => TextEditingController());

  // Step 7
  String? _sleep;
  final _complaintsCtrl   = TextEditingController();
  final Set<String> _previousInjuries = {};

  @override
  void initState() {
    super.initState();
    // Prefill vanuit auth state (register-fase-2 of Strava/Google-naam)
    final auth = ref.read(authProvider);
    if (auth.displayName != null) _nameCtrl.text = auth.displayName!;
    if (auth.dateOfBirth != null) _dateOfBirth = auth.dateOfBirth;
    if (auth.gender != null) _gender = auth.gender;

    // Als alle drie al ingevuld zijn, sla stap 1 over
    if (_nameCtrl.text.isNotEmpty &&
        _dateOfBirth != null &&
        _gender != null) {
      _step1Prefilled = true;
      _step = 2;
      _fromStep = 2;
    }

    // Welkomstslide tonen voor nieuwe accounts
    if (widget.showWelcome) {
      _showingWelcome = true;
    }

    // Initialiseer zones met Karvonen defaults (leeftijd 30, rest 55)
    _recalcZones(forceUpdate: true);
  }

  /// Herbereken hartslagzones op basis van max/rust HR. Overschrijft alleen als [forceUpdate].
  void _recalcZones({bool forceUpdate = false}) {
    final dob = _dateOfBirth ?? DateTime(DateTime.now().year - 30);
    final today = DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
    final maxHr  = _hrAuto ? (220 - age) : (int.tryParse(_maxHrCtrl.text) ?? (220 - age));
    final restHr = int.tryParse(_restHrCtrl.text) ?? 55;
    final hrr    = (maxHr - restHr).toDouble();
    int kv(double f) => (restHr + hrr * f).round();
    final lows  = [kv(0.50), kv(0.60), kv(0.70), kv(0.80), kv(0.90)];
    final highs = [kv(0.60), kv(0.70), kv(0.80), kv(0.90), maxHr];
    for (int i = 0; i < 5; i++) {
      if (forceUpdate || _zoneLoCtrls[i].text.isEmpty) _zoneLoCtrls[i].text = lows[i].toString();
      if (forceUpdate || _zoneHiCtrls[i].text.isEmpty) _zoneHiCtrls[i].text = highs[i].toString();
    }
  }

  // Hoe stap en totaal worden getoond in de indicator
  int get _displayStep  => _step1Prefilled ? _step - 1 : _step;
  int get _displayTotal => _step1Prefilled ? _totalSteps - 1 : _totalSteps;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxHrCtrl.dispose();
    _restHrCtrl.dispose();
    for (final c in [..._zoneLoCtrls, ..._zoneHiCtrls]) c.dispose();
    _complaintsCtrl.dispose();
    super.dispose();
  }

  bool get _isUnderSixteen {
    if (_dateOfBirth == null) return false;
    final today = DateTime.now();
    var age = today.year - _dateOfBirth!.year;
    if (today.month < _dateOfBirth!.month ||
        (today.month == _dateOfBirth!.month && today.day < _dateOfBirth!.day)) {
      age--;
    }
    return age < 16;
  }

  String get _dobLabel {
    if (_dateOfBirth == null) return 'Geboortedatum kiezen';
    return '${_dateOfBirth!.day.toString().padLeft(2, '0')}-'
        '${_dateOfBirth!.month.toString().padLeft(2, '0')}-'
        '${_dateOfBirth!.year}';
  }

  // ── Duration helpers ──────────────────────────────────────────────────────

  /// Formatteer Duration als "h:mm:ss" of null als leeg.
  String? _formatDuration(Duration? d) {
    if (d == null) return null;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Open duration picker bottom sheet, sla resultaat op via [onPicked].
  Future<void> _pickDuration(Duration? initial, void Function(Duration?) onPicked) async {
    final init = initial ?? const Duration(hours: 0, minutes: 30);
    int selH = init.inHours.clamp(0, 9);
    int selM = init.inMinutes.remainder(60);
    int selS = init.inSeconds.remainder(60);

    final FixedExtentScrollController hCtrl = FixedExtentScrollController(initialItem: selH);
    final FixedExtentScrollController mCtrl = FixedExtentScrollController(initialItem: selM);
    final FixedExtentScrollController sCtrl = FixedExtentScrollController(initialItem: selS);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tijd invoeren',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onBg)),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Column headers
                Row(children: const [
                  Expanded(child: Center(child: Text('uur', style: TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.w600)))),
                  SizedBox(width: 8),
                  Expanded(child: Center(child: Text('min', style: TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.w600)))),
                  SizedBox(width: 8),
                  Expanded(child: Center(child: Text('sec', style: TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.w600)))),
                ]),
                const SizedBox(height: 8),
                // Wheels
                SizedBox(
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Selection highlight
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.outline),
                        ),
                      ),
                      Row(children: [
                        // Hours (0–9)
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: hCtrl,
                            itemExtent: 44,
                            diameterRatio: 1.4,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (i) => setDialogState(() => selH = i),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 10,
                              builder: (_, i) => Center(
                                child: Text('$i', style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w600,
                                  color: selH == i ? AppColors.brand : AppColors.onSurface,
                                )),
                              ),
                            ),
                          ),
                        ),
                        const Text(':', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onBg)),
                        // Minutes (0–59)
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: mCtrl,
                            itemExtent: 44,
                            diameterRatio: 1.4,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (i) => setDialogState(() => selM = i),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 60,
                              builder: (_, i) => Center(
                                child: Text(i.toString().padLeft(2, '0'), style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w600,
                                  color: selM == i ? AppColors.brand : AppColors.onSurface,
                                )),
                              ),
                            ),
                          ),
                        ),
                        const Text(':', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onBg)),
                        // Seconds (0–59)
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: sCtrl,
                            itemExtent: 44,
                            diameterRatio: 1.4,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (i) => setDialogState(() => selS = i),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 60,
                              builder: (_, i) => Center(
                                child: Text(i.toString().padLeft(2, '0'), style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w600,
                                  color: selS == i ? AppColors.brand : AppColors.onSurface,
                                )),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(ctx); onPicked(null); },
              child: const Text('Wissen', style: TextStyle(color: AppColors.muted)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                onPicked(Duration(hours: selH, minutes: selM, seconds: selS));
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    hCtrl.dispose();
    mCtrl.dispose();
    sCtrl.dispose();
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
      case 1: return _nameCtrl.text.isNotEmpty && _dateOfBirth != null && !_isUnderSixteen && _gender != null;
      case 2: return _runningYears != null;
      case 3: return true; // optional
      case 4: return _raceGoal != null && _raceDate != null && _terrain != null;
      case 5: return _trainingDays.length >= 2 && _longRunDay != null && _trainingDays.contains(_longRunDay);
      case 6: return true; // optional
      case 7: return _sleep != null;
      default: return true;
    }
  }

  void _nextStep() {
    if (_step < _totalSteps) {
      setState(() { _fromStep = _step; _step++; });
    } else {
      _submit();
    }
  }

  void _prevStep() {
    final minStep = _step1Prefilled ? 2 : 1;
    if (_step > minStep) {
      setState(() { _fromStep = _step; _step--; });
    } else if (widget.showWelcome) {
      setState(() => _showingWelcome = true);
    }
  }

  void _skipStep() {
    if (_step < _totalSteps) setState(() { _fromStep = _step; _step++; });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final client = ref.read(apiClientProvider);
      final dob = _dateOfBirth ?? DateTime(1990);
      final today = DateTime.now();
      var age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;

      final profile = {
        'id':             'ffffffff-ffff-ffff-ffff-ffffffffffff',
        'user_id':        'ffffffff-ffff-ffff-ffff-ffffffffffff',
        'name':           _nameCtrl.text.trim(),
        'date_of_birth':  '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
        'gender':         _gender ?? 'other',
        'running_years':   _runningYears ?? 'two_to_five_years',
        'weekly_km':       _weeklyKm,
        'previous_ultra':  _previousUltra,
        'time_10k':           _formatDuration(_time10k),
        'time_half_marathon': _formatDuration(_timeHalf),
        'time_marathon':      _formatDuration(_timeMarathon),
        'race_goal':          _raceGoalCustomKm != null
            ? {'custom': {'distance_km': _raceGoalCustomKm}}
            : _raceGoal,
        'race_time_goal':     _formatDuration(_raceTimeGoal),
        'race_date':       _raceDate?.toIso8601String().split('T')[0],
        'terrain':         _terrain ?? 'road',
        'training_days':   _trainingDays.toList()..sort(),
        'strength_days':   _strengthDays.toList()..sort(),
        'max_duration_per_day': _trainingDays.map((d) => {
          'day': d,
          'max_minutes': _dayDurations[d] ?? 60,
        }).toList(),
        'long_run_day':    _longRunDay,
        'max_hr':          _hrAuto
            ? (220 - age)
            : (_maxHrCtrl.text.isNotEmpty ? int.tryParse(_maxHrCtrl.text) : null),
        'rest_hr':         int.tryParse(_restHrCtrl.text) ?? 55,
        'hr_zones': [
          for (int i = 0; i < 5; i++) {
            'num': i + 1,
            'name': ['Herstel', 'Aerobe basis', 'Aerobe drempel', 'Anaerobe drempel', 'VO₂max'][i],
            'lo':  int.tryParse(_zoneLoCtrls[i].text) ?? 0,
            'hi':  int.tryParse(_zoneHiCtrls[i].text) ?? 0,
            'color': ['#7bc67e', '#5a7a52', '#c49a5a', '#b85c3a', '#c0392b'][i],
            'description': ['Actief herstel, wandelen', 'Lange duurlopen, praattempo',
              'Tempoduurloop, comfortabel', 'Tempolopen, lactaatdrempel',
              'Intervaltraining, max inspanning'][i],
          }
        ],
        'sleep_hours':     _sleep ?? 'seven_to_eight',
        'complaints':      _complaintsCtrl.text.isNotEmpty ? _complaintsCtrl.text : null,
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
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevStep)
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
                children: List.generate(_displayTotal, (i) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: i < _displayStep ? AppColors.brand : AppColors.outline,
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
              padding: EdgeInsets.fromLTRB(20, 0, 20,
                  MediaQuery.of(context).viewInsets.bottom + 16),
              child: FilledButton.icon(
                onPressed: (_canNext && !_submitting) ? _nextStep : null,
                icon: _submitting
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Icon(
                        _step == _totalSteps
                            ? Icons.rocket_launch_outlined
                            : Icons.arrow_forward,
                        size: 18),
                label: Text(_step == _totalSteps ? 'Plan aanmaken' : 'Volgende'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    final name = ref.read(authProvider).displayName;
    final greeting = (name != null && name.isNotEmpty) ? 'Welkom, $name!' : 'Welkom bij Endurance!';

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

              // Icon
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'We gaan nu een persoonlijk trainingsplan voor je opmaken.\nDit duurt ongeveer 2 minuten.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Feature list
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
                              child: Text(f.$1, style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.$2,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.onBg,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  f.$3,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                    height: 1.4,
                                  ),
                                ),
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
      1 => _stepPersonal(),
      2 => _stepExperience(),
      3 => _stepPerformance(),
      4 => _stepRaceGoal(),
      5 => _stepTrainingDays(),
      6 => _stepHeartrate(),
      7 => _stepHealth(),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Step 1: Personal ─────────────────────────────────────────────────────────

  Widget _stepPersonal() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeader(emoji: '👤', title: 'Over jezelf',
          subtitle: 'We personaliseren je plan op basis van jouw profiel'),
      TextField(
        controller: _nameCtrl,
        style: const TextStyle(color: AppColors.onBg),
        decoration: const InputDecoration(
          labelText: 'Voornaam',
          hintText: 'Bijv. Sanne',
          prefixIcon: Icon(Icons.person_outline, size: 18),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: _pickDateOfBirth,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Geboortedatum',
            prefixIcon: const Icon(Icons.cake_outlined, size: 18),
            errorText: _isUnderSixteen
                ? 'Je moet minimaal 16 jaar oud zijn om deze app te gebruiken.'
                : null,
          ),
          child: Text(
            _dobLabel,
            style: TextStyle(
              color: _dateOfBirth == null ? AppColors.muted : AppColors.onBg,
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      _SectionLabel('Geslacht'),
      _ChipRow(
        values:   ['male', 'female', 'other'],
        labels:   ['Man', 'Vrouw', 'Anders'],
        selected: _gender,
        onSelect: (v) => setState(() => _gender = v),
      ),
    ],
  );

  // ── Step 2: Experience ───────────────────────────────────────────────────────

  Widget _stepExperience() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeader(emoji: '🏃', title: 'Loopervaring',
          subtitle: 'Hoeveel ervaring heb je als hardloper?'),
      _SectionLabel('Hoe lang loop je al?'),
      _ChipRow(
        values: [
          'less_than_two_years', 'two_to_five_years',
          'five_to_ten_years', 'more_than_ten_years',
        ],
        labels: ['< 2 jaar', '2-5 jaar', '5-10 jaar', '10+ jaar'],
        selected: _runningYears,
        onSelect: (v) => setState(() => _runningYears = v),
      ),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _SectionLabel('Weekkilometrage'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${_weeklyKm.round()} km/week',
              style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800)),
        ),
      ]),
      Row(children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 20, color: AppColors.muted),
          onPressed: _weeklyKm > 0
              ? () => setState(() => _weeklyKm = (_weeklyKm - 5).clamp(0, 150))
              : null,
        ),
        Expanded(
          child: Slider(
            value: _weeklyKm,
            min: 0, max: 150, divisions: 30,
            onChanged: (v) => setState(() => _weeklyKm = v),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 20, color: AppColors.muted),
          onPressed: _weeklyKm < 150
              ? () => setState(() => _weeklyKm = (_weeklyKm + 5).clamp(0, 150))
              : null,
        ),
      ]),
    ],
  );

  // ── Step 3: Performance (optional) ──────────────────────────────────────────

  Widget _stepPerformance() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeader(emoji: '🏅', title: 'Prestaties',
          subtitle: 'Optioneel — sla over als je geen persoonlijke records hebt'),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.muted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Deze informatie helpt ons je trainingsintensite nauwkeuriger te berekenen.',
              style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      _DurationField(
        label: '10 km tijd (optioneel)',
        value: _time10k,
        onTap: () => _pickDuration(_time10k, (d) => setState(() => _time10k = d)),
      ),
      const SizedBox(height: 14),
      _DurationField(
        label: 'Halve marathon tijd (optioneel)',
        value: _timeHalf,
        onTap: () => _pickDuration(_timeHalf, (d) => setState(() => _timeHalf = d)),
      ),
      const SizedBox(height: 14),
      _DurationField(
        label: 'Marathon tijd (optioneel)',
        value: _timeMarathon,
        onTap: () => _pickDuration(_timeMarathon, (d) => setState(() => _timeMarathon = d)),
      ),
    ],
  );

  // ── Step 4: Race goal ────────────────────────────────────────────────────────

  Widget _stepRaceGoal() {
    final raceDateStr = _raceDate == null
        ? null
        : '${_raceDate!.day.toString().padLeft(2, '0')}-'
          '${_raceDate!.month.toString().padLeft(2, '0')}-${_raceDate!.year}';
    final weeksUntil = _raceDate == null
        ? null
        : _raceDate!.difference(DateTime.now()).inDays ~/ 7;
    final peakKm = _weeklyKm * 1.4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(emoji: '🏔️', title: 'Race & doelstelling',
            subtitle: 'Waarvoor train je?'),

        // Category: Eerste stappen
        _SectionLabel('Eerste stappen'),
        _ChipRow(
          values: ['five_km', 'ten_km'],
          labels: ['5 km', '10 km'],
          selected: _raceGoal,
          onSelect: (v) => setState(() { _raceGoal = v; _raceGoalCustomKm = null; }),
        ),
        const SizedBox(height: 16),

        // Category: Marathon
        _SectionLabel('Marathon'),
        _ChipRow(
          values: ['half_marathon', 'marathon', 'sub3_marathon', 'sub4_marathon'],
          labels: ['Halve marathon', 'Marathon', 'Sub-3 marathon', 'Sub-4 marathon'],
          selected: _raceGoal,
          onSelect: (v) => setState(() { _raceGoal = v; _raceGoalCustomKm = null; }),
        ),
        const SizedBox(height: 16),

        // Category: Ultra
        _SectionLabel('Ultra'),
        _ChipRow(
          values: ['fifty_km', 'hundred_km'],
          labels: ['50 km', '100 km'],
          selected: _raceGoal,
          onSelect: (v) => setState(() { _raceGoal = v; _raceGoalCustomKm = null; }),
        ),
        const SizedBox(height: 16),

        // Category: Custom
        _SectionLabel('Eigen afstand'),
        GestureDetector(
          onTap: () => setState(() {
            _raceGoal = 'custom';
            _raceGoalCustomKm ??= 42.195;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _raceGoal == 'custom'
                  ? AppColors.brand.withValues(alpha: .15)
                  : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _raceGoal == 'custom' ? AppColors.brand : AppColors.outline,
                width: _raceGoal == 'custom' ? 2 : 1,
              ),
            ),
            child: Text('Eigen afstand invoeren',
                style: TextStyle(
                  fontSize: 13,
                  color: _raceGoal == 'custom' ? AppColors.brand : AppColors.onSurface,
                  fontWeight: _raceGoal == 'custom' ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
        ),
        if (_raceGoal == 'custom') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Slider(
                value: _raceGoalCustomKm ?? 42.0,
                min: 5, max: 250, divisions: 49,
                onChanged: (v) => setState(() => _raceGoalCustomKm = v),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${(_raceGoalCustomKm ?? 42).round()} km',
                  style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800)),
            ),
          ]),
        ],
        const SizedBox(height: 20),

        // Race date
        _SectionLabel('Racedatum'),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _raceDate ?? DateTime.now().add(const Duration(days: 90)),
              firstDate: DateTime.now().add(const Duration(days: 14)),
              lastDate: DateTime.now().add(const Duration(days: 730)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: Theme.of(ctx).colorScheme.copyWith(
                    primary: AppColors.brand,
                    surface: AppColors.surfaceHigher,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _raceDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _raceDate != null ? AppColors.brand : AppColors.outline,
                width: _raceDate != null ? 2 : 1,
              ),
            ),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined, size: 18,
                  color: _raceDate != null ? AppColors.brand : AppColors.muted),
              const SizedBox(width: 10),
              Text(
                raceDateStr ?? 'Kies een datum',
                style: TextStyle(
                  fontSize: 14,
                  color: _raceDate != null ? AppColors.onBg : AppColors.muted,
                ),
              ),
            ]),
          ),
        ),

        if (_raceDate != null && weeksUntil != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brand.withValues(alpha: .25)),
            ),
            child: Row(children: [
              const Icon(Icons.preview_outlined, size: 16, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Preview: $weeksUntil weken schema, '
                'piekkilometrage ~${peakKm.round()} km/week',
                style: const TextStyle(
                  fontSize: 12, color: AppColors.brand, height: 1.4),
              )),
            ]),
          ),
        ],

        const SizedBox(height: 20),
        _SectionLabel('Ondergrond'),
        _ChipRow(
          values: ['road', 'mixed', 'trail'],
          labels: ['Weg', 'Mixed', 'Trail'],
          selected: _terrain,
          onSelect: (v) => setState(() => _terrain = v),
        ),

        if (_raceGoal != null) ...[
          const SizedBox(height: 20),
          _SectionLabel('Tijdsdoelstelling (optioneel)'),
          _DurationField(
            label: 'Streeftijd',
            value: _raceTimeGoal,
            onTap: () => _pickDuration(_raceTimeGoal, (d) => setState(() => _raceTimeGoal = d)),
          ),
        ],
      ],
    );
  }

  // ── Step 5: Training days ────────────────────────────────────────────────────

  Widget _stepTrainingDays() {
    const dayLabels      = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
    const dayLabelsFull  = ['Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrijdag', 'Zaterdag', 'Zondag'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(emoji: '📅', title: 'Trainingsdagen',
            subtitle: 'Op welke dagen wil je trainen? (min. 2 dagen)'),
        Row(
          children: List.generate(7, (i) {
            final selected = _trainingDays.contains(i);
            return Expanded(child: GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _trainingDays.remove(i);
                  _dayDurations.remove(i);
                  if (_longRunDay == i) _longRunDay = null;
                } else {
                  _trainingDays.add(i);
                  _dayDurations[i] = 60;
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.brand.withValues(alpha: .2) : AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.brand : AppColors.outline,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Center(child: Text(dayLabels[i],
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? AppColors.brand : AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ))),
              ),
            ));
          }),
        ),

        if (_trainingDays.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionLabel('Max. duur per dag'),
          ...(_trainingDays.toList()..sort()).map((d) {
            final mins = _dayDurations[d] ?? 60;
            final isLong = d == _longRunDay;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(dayLabelsFull[d],
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: isLong ? AppColors.longRun : AppColors.onBg,
                        )),
                    if (isLong) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.longRun.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Lange duurloop',
                            style: TextStyle(fontSize: 10, color: AppColors.longRun,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${mins ~/ 60 > 0 ? '${mins ~/ 60}u ' : ''}${mins % 60 > 0 || mins < 60 ? '${mins % 60}m' : ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurface,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  Slider(
                    value: mins.toDouble(),
                    min: 30, max: 240, divisions: 14,
                    onChanged: (v) => setState(() => _dayDurations[d] = v.round()),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          _SectionLabel('Welke dag is je lange duurloop?'),
          DropdownButtonFormField<int>(
            value: _trainingDays.contains(_longRunDay) ? _longRunDay : null,
            dropdownColor: AppColors.surfaceHigher,
            style: const TextStyle(color: AppColors.onBg, fontSize: 14),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.flag_outlined, size: 18),
              hintText: 'Kies een dag',
            ),
            items: (_trainingDays.toList()..sort()).map((d) =>
              DropdownMenuItem(
                value: d,
                child: Text(dayLabelsFull[d]),
              ),
            ).toList(),
            onChanged: (v) => setState(() {
              _longRunDay = v;
              if (v != null) _dayDurations[v] = 180;
            }),
          ),
        ],

        // ── Krachttraining ──────────────────────────────────────────────────
        const SizedBox(height: 28),
        _SectionLabel('Krachttraining'),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() {
            _addStrength = !_addStrength;
            if (!_addStrength) _strengthDays.clear();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _addStrength
                  ? AppColors.brand.withValues(alpha: .12)
                  : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _addStrength ? AppColors.brand : AppColors.outline,
                width: _addStrength ? 2 : 1,
              ),
            ),
            child: Row(children: [
              Icon(Icons.fitness_center,
                  size: 20,
                  color: _addStrength ? AppColors.brand : AppColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Krachttraining toevoegen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _addStrength ? AppColors.brand : AppColors.onBg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Krachttraining naast je hardloopschema',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(
                _addStrength ? Icons.check_circle : Icons.circle_outlined,
                color: _addStrength ? AppColors.brand : AppColors.muted,
                size: 22,
              ),
            ]),
          ),
        ),

        if (_addStrength) ...[
          const SizedBox(height: 16),
          const Text(
            'Op welke dag(en) wil je krachttrainen?',
            style: TextStyle(fontSize: 13, color: AppColors.onSurface),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (i) {
              final selected = _strengthDays.contains(i);
              return Expanded(child: GestureDetector(
                onTap: () => setState(() {
                  if (selected) _strengthDays.remove(i);
                  else _strengthDays.add(i);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brand.withValues(alpha: .2)
                        : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.brand : AppColors.outline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Center(child: Text(dayLabels[i],
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? AppColors.brand : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ))),
                ),
              ));
            }),
          ),
        ],
      ],
    );
  }

  // ── Step 6: Heart rate (optional) ───────────────────────────────────────────

  Widget _stepHeartrate() {
    final dob = _dateOfBirth ?? DateTime(DateTime.now().year - 30);
    final today = DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;

    const zoneNames   = ['Z1 Herstel', 'Z2 Aerobe basis', 'Z3 Aerobe drempel', 'Z4 Anaerobe drempel', 'Z5 VO₂max'];
    const zoneColors  = [Color(0xFF7bc67e), Color(0xFF5a7a52), Color(0xFFc49a5a), Color(0xFFb85c3a), Color(0xFFc0392b)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(emoji: '❤️', title: 'Hartslagzones',
            subtitle: 'Optioneel — helpt ons je trainingsintensiteit te calibreren'),

        // Auto/manual max HR toggle
        _MobilityOption(
          label: 'Automatisch berekenen (220 − leeftijd)',
          subtitle: 'Max HR = ${220 - age} bpm',
          selected: _hrAuto,
          onTap: () => setState(() {
            _hrAuto = true;
            _recalcZones(forceUpdate: true);
          }),
        ),
        const SizedBox(height: 8),
        _MobilityOption(
          label: 'Zelf invoeren',
          subtitle: 'Vul je gemeten max hartslag in',
          selected: !_hrAuto,
          onTap: () => setState(() => _hrAuto = false),
        ),

        if (!_hrAuto) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _maxHrCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.onBg),
            decoration: const InputDecoration(
              labelText: 'Max hartslag (bpm)',
              hintText: '190',
              prefixIcon: Icon(Icons.favorite_outline, size: 18),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],

        const SizedBox(height: 14),
        TextField(
          controller: _restHrCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.onBg),
          decoration: const InputDecoration(
            labelText: 'Rusthartslag (bpm)',
            hintText: '55',
            prefixIcon: Icon(Icons.bedtime_outlined, size: 18),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('JOUW ZONES', style: TextStyle(
              fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600,
              color: AppColors.muted,
            )),
            TextButton.icon(
              onPressed: () => setState(() => _recalcZones(forceUpdate: true)),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Herbereken', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(5, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: zoneColors[i], shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 130,
              child: Text(zoneNames[i],
                  style: const TextStyle(fontSize: 13, color: AppColors.onSurface)),
            ),
            Expanded(
              child: TextField(
                controller: _zoneLoCtrls[i],
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13, color: AppColors.onBg),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  hintText: 'van',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('–', style: TextStyle(color: AppColors.muted)),
            ),
            Expanded(
              child: TextField(
                controller: _zoneHiCtrls[i],
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13, color: AppColors.onBg),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  hintText: 'tot',
                  suffixText: 'bpm',
                  suffixStyle: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
        )),
      ],
    );
  }

  // ── Step 7: Health ───────────────────────────────────────────────────────────

  Widget _stepHealth() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeader(emoji: '💤', title: 'Gezondheid & herstel',
          subtitle: 'Dit helpt ons je belastbaarheid goed in te schatten'),

      _SectionLabel('Gemiddelde slaap per nacht'),
      _ChipRow(
        values: ['less_than_six', 'six_to_seven', 'seven_to_eight', 'more_than_eight'],
        labels: ['< 6 uur', '6-7 uur', '7-8 uur', '> 8 uur'],
        selected: _sleep,
        onSelect: (v) => setState(() => _sleep = v),
      ),

      const SizedBox(height: 24),
      TextField(
        controller: _complaintsCtrl,
        maxLines: 3,
        style: const TextStyle(color: AppColors.onBg),
        decoration: const InputDecoration(
          labelText: 'Huidige klachten of pijnpunten (optioneel)',
          hintText: 'Beschrijf eventuele pijn of ongemakken...',
          prefixIcon: Icon(Icons.notes_outlined, size: 18),
        ),
      ),

      const SizedBox(height: 20),
      _SectionLabel('Eerdere blessures (optioneel)'),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          'Knie', 'Achilles', 'Scheenbeen', 'Heup',
          'Hamstring', 'Kuit', 'Voet', 'Enkel', 'Onderrug',
        ].map((loc) {
          final selected = _previousInjuries.contains(loc);
          return FilterChip(
            label: Text(loc),
            selected: selected,
            onSelected: (_) => setState(() => selected
                ? _previousInjuries.remove(loc)
                : _previousInjuries.add(loc)),
          );
        }).toList(),
      ),

      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.easy.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.easy.withValues(alpha: .3)),
        ),
        child: const Row(children: [
          Text('✅', style: TextStyle(fontSize: 20)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Je persoonlijke trainingsschema wordt direct gegenereerd op basis van je profiel.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurface, height: 1.4),
            ),
          ),
        ]),
      ),
    ],
  );
}

// ── Mobility option (single-select row) ───────────────────────────────────────

class _MobilityOption extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _MobilityOption({
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand.withValues(alpha: .12) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
            color: selected ? AppColors.brand : AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: selected ? AppColors.brand : AppColors.onBg,
                  )),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Tappable veld dat een Duration toont als h:mm:ss (of placeholder als leeg).
class _DurationField extends StatelessWidget {
  final String    label;
  final Duration? value;
  final VoidCallback onTap;

  const _DurationField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  String get _display {
    if (value == null) return 'Kiezen…';
    final h = value!.inHours;
    final m = value!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = value!.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.timer_outlined, size: 18),
          suffixIcon: value != null
              ? const Icon(Icons.edit_outlined, size: 16, color: AppColors.muted)
              : null,
        ),
        child: Text(
          _display,
          style: TextStyle(
            color: value == null ? AppColors.muted : AppColors.onBg,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _StepHeader({required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ])),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> values;
  final List<String> labels;
  final String? selected;
  final void Function(String) onSelect;
  const _ChipRow({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(values.length, (i) {
        final active = selected == values[i];
        return GestureDetector(
          onTap: () => onSelect(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.brand.withValues(alpha: .15) : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.brand : AppColors.outline,
                width: active ? 2 : 1,
              ),
            ),
            child: Text(labels[i],
                style: TextStyle(
                  fontSize: 13,
                  color: active ? AppColors.brand : AppColors.onSurface,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
        );
      }),
    );
  }
}
