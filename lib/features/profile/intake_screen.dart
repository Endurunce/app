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
          'max_duration_per_day': trainingDays.map((d) => {
            'day': d,
            'max_minutes': d == _longRunDay ? 180 : 60,
          }).toList(),
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
          SnackBar(content: Text('Fout: ${e.toString()}')),
        );
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
            : const CloseButton(),
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(children: [
              Row(
                children: List.generate(_totalSteps, (i) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: i < _step ? AppColors.brand : AppColors.outline,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Stap $_step van $_totalSteps',
                    style: Theme.of(context).textTheme.labelSmall),
              ),
            ]),
          ),

          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStep(),
            ),
          ),

          // Next button
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20,
                  MediaQuery.of(context).viewInsets.bottom + 16),
              child: FilledButton.icon(
                onPressed: (_canNext && !_submitting) ? _next : null,
                icon: _submitting
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Icon(_step == _totalSteps ? Icons.rocket_launch_outlined : Icons.arrow_forward,
                        size: 18),
                label: Text(_step == _totalSteps ? 'Plan genereren' : 'Volgende'),
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

  // ── Steps ──────────────────────────────────────────────────────────────────

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
      TextField(
        controller: _ageCtrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: AppColors.onBg),
        decoration: const InputDecoration(
          labelText: 'Leeftijd',
          hintText: '28',
          prefixIcon: Icon(Icons.cake_outlined, size: 18),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 20),
      _SectionLabel('Geslacht'),
      _ChipRow(
        values: ['female', 'male', 'other'],
        labels: ['Vrouw', 'Man', 'Anders'],
        selected: _gender,
        onSelect: (v) => setState(() => _gender = v),
      ),
    ],
  );

  Widget _stepExperience() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeader(emoji: '🏃', title: 'Loopervaring',
          subtitle: 'Hoeveel ervaring heb je als hardloper?'),
      _SectionLabel('Hoe lang loop je al?'),
      _ChipRow(
        values: ['less_than_two_years','two_to_five_years','five_to_ten_years','more_than_ten_years'],
        labels: ['< 2 jaar','2–5 jaar','5–10 jaar','10+ jaar'],
        selected: _runningYears,
        onSelect: (v) => setState(() => _runningYears = v),
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SectionLabel('Weekkilometrage'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${_weeklyKm.round()} km',
                style: const TextStyle(
                  color: AppColors.brand, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      Slider(
        value: _weeklyKm,
        min: 10, max: 120, divisions: 22,
        onChanged: (v) => setState(() => _weeklyKm = v),
      ),
    ],
  );

  Widget _stepRaceGoal() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeader(emoji: '🏔️', title: 'Race & doelstelling',
          subtitle: 'Waarvoor train je?'),
      _SectionLabel('Doel'),
      ...[
        ('five_km',       '5 km',            '🏃'),
        ('ten_km',        '10 km',           '🏃'),
        ('half_marathon', 'Halve marathon',  '🥈'),
        ('marathon',      'Marathon',        '🥇'),
        ('fifty_km',      '50 km ultra',     '🏔️'),
        ('hundred_km',    '100 km ultra',    '🌋'),
      ].map((g) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _RadioTile(
          label: g.$2,
          emoji: g.$3,
          value: g.$1,
          groupValue: _raceGoal,
          onChanged: (v) => setState(() => _raceGoal = v),
        ),
      )),
      const SizedBox(height: 16),
      TextField(
        style: const TextStyle(color: AppColors.onBg),
        decoration: const InputDecoration(
          labelText: 'Racedatum',
          hintText: 'JJJJ-MM-DD',
          prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
        ),
        onChanged: (v) => setState(() => _raceDate = v),
      ),
      const SizedBox(height: 16),
      _SectionLabel('Ondergrond'),
      _ChipRow(
        values: ['road', 'trail', 'mixed'],
        labels: ['Weg', 'Trail', 'Mix'],
        selected: _terrain,
        onSelect: (v) => setState(() => _terrain = v),
      ),
    ],
  );

  Widget _stepTrainingDays() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeader(emoji: '📅', title: 'Trainingsdagen',
          subtitle: 'Op welke dagen wil je trainen?'),
      const SizedBox(height: 8),
      Row(
        children: List.generate(7, (i) {
          const labels = ['Ma','Di','Wo','Do','Vr','Za','Zo'];
          final selected = _trainingDays.contains(i);
          return Expanded(child: GestureDetector(
            onTap: () => setState(() =>
                selected ? _trainingDays.remove(i) : _trainingDays.add(i)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.brand.withOpacity(.2) : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.brand : AppColors.outline,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(child: Text(labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? AppColors.brand : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ))),
            ),
          ));
        }),
      ),
      const SizedBox(height: 24),
      _SectionLabel('Lange duurloop op'),
      DropdownButtonFormField<int>(
        value: _longRunDay,
        dropdownColor: AppColors.surfaceHigher,
        style: const TextStyle(color: AppColors.onBg, fontSize: 14),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.flag_outlined, size: 18),
        ),
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
      _StepHeader(emoji: '💤', title: 'Gezondheid & herstel',
          subtitle: 'Dit helpt ons je belastbaarheid goed in te schatten'),
      _SectionLabel('Gemiddeld slaap per nacht'),
      _ChipRow(
        values: ['less_than_six','six_to_seven','seven_to_eight','more_than_eight'],
        labels: ['< 6 uur','6–7 uur','7–8 uur','> 8 uur'],
        selected: _sleep,
        onSelect: (v) => setState(() => _sleep = v),
      ),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.easy.withOpacity(.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.easy.withOpacity(.3)),
        ),
        child: Row(children: [
          const Text('✅', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          const Expanded(
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

// ── Helpers ───────────────────────────────────────────────────────────────────

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
            color: AppColors.brand.withOpacity(.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
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
  final String selected;
  final void Function(String) onSelect;
  const _ChipRow({required this.values, required this.labels,
      required this.selected, required this.onSelect});

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
              color: active ? AppColors.brand.withOpacity(.15) : AppColors.surfaceHigh,
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

class _RadioTile extends StatelessWidget {
  final String label;
  final String emoji;
  final String value;
  final String groupValue;
  final void Function(String) onChanged;
  const _RadioTile({required this.label, required this.emoji,
      required this.value, required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand.withOpacity(.12) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: selected ? AppColors.brand : AppColors.onBg))),
          if (selected)
            const Icon(Icons.check_circle, size: 18, color: AppColors.brand),
        ]),
      ),
    );
  }
}
