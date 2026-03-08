import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/plan/plan_provider.dart';
import '../../shared/theme/app_theme.dart';

class IntakeScreen extends ConsumerStatefulWidget {
  const IntakeScreen({super.key});

  @override
  ConsumerState<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends ConsumerState<IntakeScreen> {
  int _step = 1;
  static const _totalSteps = 5;
  bool _submitting = false;

  // Profile data
  final _nameCtrl      = TextEditingController();
  final _ageCtrl       = TextEditingController();
  String _gender       = 'female';
  String _runningYears = 'two_to_five_years';
  double _weeklyKm     = 40;
  String _raceGoal     = 'half_marathon';
  String _raceDate     = '';
  String _terrain      = 'road';
  final Set<int> _trainingDays = {1, 3, 5, 6};
  int _longRunDay = 6;
  String _sleep = 'seven_to_eight';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  bool get _canNext {
    if (_step == 1) return _nameCtrl.text.isNotEmpty && _ageCtrl.text.isNotEmpty;
    if (_step == 3) return _raceDate.isNotEmpty;
    return true;
  }

  void _next() {
    if (_step < _totalSteps) setState(() => _step++);
    else _submit();
  }

  void _back() {
    if (_step > 1) setState(() => _step--);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final userId = ref.read(authProvider).userId ?? '';
      final client = ref.read(apiClientProvider);

      final trainingDays = _trainingDays.toList()..sort();
      final maxDuration = trainingDays.map((d) => {
        'day': d,
        'max_minutes': d == _longRunDay ? 180 : 60,
      }).toList();

      await client.post('/api/plans/generate', {
        'profile': {
          'id':      'ffffffff-ffff-ffff-ffff-ffffffffffff',
          'user_id': userId,
          'name':    _nameCtrl.text.trim(),
          'age':     int.parse(_ageCtrl.text),
          'gender':  _gender,
          'running_years':   _runningYears,
          'weekly_km':       _weeklyKm,
          'previous_ultra':  'none',
          'time_10k':        null,
          'time_half_marathon': null,
          'time_marathon':   null,
          'race_goal':       _raceGoal,
          'race_date':       _raceDate,
          'terrain':         _terrain,
          'training_days':   trainingDays,
          'max_duration_per_day': maxDuration,
          'long_run_day':    _longRunDay,
          'max_hr':          null,
          'rest_hr':         55,
          'hr_zones':        null,
          'sleep_hours':     _sleep,
          'complaints':      null,
          'previous_injuries': [],
        },
      });

      await ref.read(planProvider.notifier).loadActivePlan();
      if (mounted) context.go('/plan');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jouw plan opmaken'),
        leading: _step > 1
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back)
            : null,
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: List.generate(_totalSteps, (i) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: i < _step ? AppColors.moss : AppColors.border,
                  ),
                ),
              )),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Stap $_step van $_totalSteps',
                  style: const TextStyle(fontSize: 11, color: AppColors.inkLight)),
            ),
          ),

          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStep(),
            ),
          ),

          // Footer
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20,
                MediaQuery.of(context).viewInsets.bottom + 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_canNext && !_submitting) ? _next : null,
                child: _submitting
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_step == _totalSteps ? 'Plan genereren 🚀' : 'Volgende'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      1 => _stepPersonal(),
      2 => _stepExperience(),
      3 => _stepRaceGoal(),
      4 => _stepTrainingDays(),
      5 => _stepHealth(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _stepPersonal() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header('👤', 'Over jezelf'),
      _label('Voornaam'),
      TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Bijv. Sanne')),
      const SizedBox(height: 16),
      _label('Leeftijd'),
      TextField(controller: _ageCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '28')),
      const SizedBox(height: 16),
      _label('Geslacht'),
      _chipRow(['female', 'male', 'other'], ['Vrouw', 'Man', 'Anders'],
          _gender, (v) => setState(() => _gender = v)),
    ],
  );

  Widget _stepExperience() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header('🏃', 'Loopervaring'),
      _label('Hoe lang loop je al?'),
      _chipRow(
        ['less_than_two_years','two_to_five_years','five_to_ten_years','more_than_ten_years'],
        ['< 2 jaar','2–5 jaar','5–10 jaar','10+ jaar'],
        _runningYears, (v) => setState(() => _runningYears = v),
      ),
      const SizedBox(height: 20),
      _label('Weekkilometrage: ${_weeklyKm.round()} km'),
      Slider(
        value: _weeklyKm,
        min: 10, max: 120, divisions: 22,
        activeColor: AppColors.moss,
        onChanged: (v) => setState(() => _weeklyKm = v),
      ),
    ],
  );

  Widget _stepRaceGoal() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header('🏔️', 'Race & doelstelling'),
      _label('Doel'),
      ...[
        ('five_km',       '5 km'),
        ('ten_km',        '10 km'),
        ('half_marathon', 'Halve marathon'),
        ('marathon',      'Marathon'),
        ('fifty_km',      '50 km ultra'),
        ('hundred_km',    '100 km ultra'),
      ].map((g) => RadioListTile<String>(
        title: Text(g.$2),
        value: g.$1,
        groupValue: _raceGoal,
        activeColor: AppColors.moss,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => setState(() => _raceGoal = v!),
      )),
      const SizedBox(height: 8),
      _label('Racedatum'),
      TextField(
        decoration: const InputDecoration(hintText: 'JJJJ-MM-DD', prefixIcon: Icon(Icons.calendar_today, size: 18)),
        onChanged: (v) => setState(() => _raceDate = v),
      ),
      const SizedBox(height: 16),
      _label('Ondergrond'),
      _chipRow(['road','trail','mixed'], ['Weg','Trail','Mix'],
          _terrain, (v) => setState(() => _terrain = v)),
    ],
  );

  Widget _stepTrainingDays() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header('📅', 'Trainingsdagen'),
      _label('Op welke dagen train je?'),
      const SizedBox(height: 8),
      Row(
        children: List.generate(7, (i) {
          const labels = ['Ma','Di','Wo','Do','Vr','Za','Zo'];
          final selected = _trainingDays.contains(i);
          return Expanded(child: GestureDetector(
            onTap: () => setState(() =>
                selected ? _trainingDays.remove(i) : _trainingDays.add(i)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.moss : AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? AppColors.moss : AppColors.border),
              ),
              child: Column(children: [
                Text(labels[i],
                    style: TextStyle(fontSize: 12,
                        color: selected ? Colors.white : AppColors.inkMid,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ));
        }),
      ),
      const SizedBox(height: 20),
      _label('Lange duurloop op'),
      DropdownButtonFormField<int>(
        value: _longRunDay,
        decoration: const InputDecoration(),
        items: _trainingDays.map((d) {
          const labels = ['Maandag','Dinsdag','Woensdag','Donderdag','Vrijdag','Zaterdag','Zondag'];
          return DropdownMenuItem(value: d, child: Text(labels[d]));
        }).toList(),
        onChanged: (v) => setState(() => _longRunDay = v!),
      ),
    ],
  );

  Widget _stepHealth() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header('💤', 'Gezondheid & herstel'),
      _label('Gemiddeld slaap per nacht'),
      _chipRow(
        ['less_than_six','six_to_seven','seven_to_eight','more_than_eight'],
        ['< 6u','6–7u','7–8u','> 8u'],
        _sleep, (v) => setState(() => _sleep = v),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.mossDim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.moss.withOpacity(.3)),
        ),
        child: const Text(
          '✅ Je persoonlijke trainingsschema wordt direct gegenereerd op basis van je profiel. Je kunt het daarna altijd aanpassen.',
          style: TextStyle(fontSize: 13, color: AppColors.ink),
        ),
      ),
    ],
  );

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _header(String emoji, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: AppColors.mossDim, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
      ),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 18,
          fontWeight: FontWeight.w700, color: AppColors.ink)),
    ]),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(text.toUpperCase(),
        style: const TextStyle(fontSize: 10, letterSpacing: 2, color: AppColors.inkLight)),
  );

  Widget _chipRow(List<String> values, List<String> labels, String selected, void Function(String) onSelect) =>
    Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(values.length, (i) {
        final active = selected == values[i];
        return GestureDetector(
          onTap: () => onSelect(values[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.moss.withOpacity(.12) : AppColors.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? AppColors.moss : AppColors.border, width: 1.5),
            ),
            child: Text(labels[i],
                style: TextStyle(fontSize: 13,
                    color: active ? AppColors.moss : AppColors.inkMid,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          ),
        );
      }),
    );
}
