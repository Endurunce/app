import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import 'plan_provider.dart';
import 'session_type_style.dart';

class WeekDetailScreen extends ConsumerWidget {
  final int weekNumber;
  const WeekDetailScreen({super.key, required this.weekNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider).plan;
    if (plan == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final week = plan.weeks.firstWhere((w) => w.weekNumber == weekNumber);

    return Scaffold(
      appBar: AppBar(
        title: Text('Week $weekNumber — ${week.phaseLabel}'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: week.days.length,
        itemBuilder: (ctx, i) {
          final day = week.days[i];
          return _DayCard(day: day, week: week, plan: plan);
        },
      ),
    );
  }
}

class _DayCard extends ConsumerStatefulWidget {
  final Day day;
  final Week week;
  final TrainingPlan plan;

  const _DayCard({required this.day, required this.week, required this.plan});

  @override
  ConsumerState<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends ConsumerState<_DayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final s   = styleFor(day.sessionType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Main row
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: day.sessionType == 'rest'
                ? null
                : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Emoji badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(s.emoji, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),

                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dayNames[day.weekday],
                        style: const TextStyle(fontSize: 11, color: AppColors.inkLight,
                            letterSpacing: 1.5, fontWeight: FontWeight.w500)),
                    Text(s.label,
                        style: const TextStyle(fontWeight: FontWeight.w600,
                            fontSize: 15, color: AppColors.ink)),
                    if (s.paceNote.isNotEmpty)
                      Text(s.paceNote, style: const TextStyle(fontSize: 12, color: AppColors.inkMid)),
                  ],
                )),

                // KM + done badge
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (day.sessionType != 'rest' && day.sessionType != 'cross')
                    Text('${day.effectiveKm.toStringAsFixed(1)} km',
                        style: TextStyle(fontFamily: 'Georgia', fontSize: 18,
                            fontWeight: FontWeight.w700, color: s.color)),
                  if (day.completed)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.mossDim, borderRadius: BorderRadius.circular(99)),
                      child: const Text('✓ Klaar',
                          style: TextStyle(fontSize: 10, color: AppColors.moss, fontWeight: FontWeight.w600)),
                    ),
                ]),
              ]),
            ),
          ),

          // Expandable feedback form
          if (_expanded && !day.completed)
            _FeedbackForm(day: day, week: widget.week, plan: widget.plan,
                onDone: () => setState(() => _expanded = false)),
        ],
      ),
    );
  }
}

class _FeedbackForm extends ConsumerStatefulWidget {
  final Day day;
  final Week week;
  final TrainingPlan plan;
  final VoidCallback onDone;

  const _FeedbackForm({required this.day, required this.week, required this.plan, required this.onDone});

  @override
  ConsumerState<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<_FeedbackForm> {
  int _feeling = 3;
  bool _pain = false;
  final _notesCtrl = TextEditingController();
  final _kmCtrl    = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _kmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(planProvider.notifier).completeDay(
        planId:     widget.plan.id,
        weekNumber: widget.week.weekNumber,
        weekday:    widget.day.weekday,
        feeling:    _feeling,
        pain:       _pain,
        notes:      _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        actualKm:   double.tryParse(_kmCtrl.text),
      );
      widget.onDone();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Feeling
          const Text('HOE VOELDE HET?',
              style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppColors.inkLight)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final val = i + 1;
              final emojis = ['😫', '😓', '😐', '😊', '🤩'];
              final selected = _feeling == val;
              return GestureDetector(
                onTap: () => setState(() => _feeling = val),
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.moss : AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? AppColors.moss : AppColors.border),
                  ),
                  child: Center(child: Text(emojis[i], style: const TextStyle(fontSize: 22))),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // Pain toggle
          Row(children: [
            Checkbox(
              value: _pain,
              activeColor: AppColors.terra,
              onChanged: (v) => setState(() => _pain = v ?? false),
            ),
            const Text('Pijn of ongemak tijdens sessie',
                style: TextStyle(fontSize: 13, color: AppColors.ink)),
          ]),

          // Actual km
          const SizedBox(height: 10),
          TextField(
            controller: _kmCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Werkelijk gelopen km (optioneel)',
              suffixText: 'km',
            ),
          ),

          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notities (optioneel)',
              hintText: 'Hoe ging het? Bijzonderheden?',
            ),
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Sessie afronden ✓'),
            ),
          ),
        ],
      ),
    );
  }
}
