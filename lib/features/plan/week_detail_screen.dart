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
    if (plan == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final week = plan.weeks.firstWhere((w) => w.weekNumber == weekNumber);
    final completed = week.completedCount;
    final total = week.activeDays.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Week $weekNumber'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              _PhaseBadge(week.phaseLabel),
              if (week.isRecovery) ...[
                const SizedBox(width: 8),
                _PhaseBadge('Herstelweek'),
              ],
              const Spacer(),
              Text('$completed / $total klaar',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: week.days.length,
        itemBuilder: (ctx, i) => _DayCard(
          day: week.days[i],
          week: week,
          plan: plan,
        ),
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  final String label;
  const _PhaseBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brand.withOpacity(.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(
            fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Day card ──────────────────────────────────────────────────────────────────

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
  final _style = ValueNotifier<SessionStyle?>(null);

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final s   = styleFor(day.sessionType);
    final isRest = day.sessionType == 'rest';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: isRest ? null : () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  // Type icon
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: s.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(s.emoji,
                        style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 14),

                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dayNames[day.weekday].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10, letterSpacing: 2,
                            color: AppColors.muted, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(s.label,
                          style: Theme.of(context).textTheme.titleSmall),
                      if (s.paceNote.isNotEmpty)
                        Text(s.paceNote,
                            style: const TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                    ],
                  )),

                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    if (!isRest && day.sessionType != 'cross')
                      Text('${day.effectiveKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: s.color)),
                    const SizedBox(height: 4),
                    if (day.completed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.easy.withOpacity(.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('✓ Klaar',
                            style: TextStyle(
                              fontSize: 11, color: AppColors.easy,
                              fontWeight: FontWeight.w700)),
                      )
                    else if (!isRest)
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18, color: AppColors.muted,
                      ),
                  ]),
                ]),
              ),
            ),

            if (_expanded && !day.completed)
              _FeedbackForm(
                day: widget.day,
                week: widget.week,
                plan: widget.plan,
                sessionColor: s.color,
                onDone: () => setState(() => _expanded = false),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Feedback form ─────────────────────────────────────────────────────────────

class _FeedbackForm extends ConsumerStatefulWidget {
  final Day day;
  final Week week;
  final TrainingPlan plan;
  final Color sessionColor;
  final VoidCallback onDone;

  const _FeedbackForm({
    required this.day, required this.week, required this.plan,
    required this.sessionColor, required this.onDone,
  });

  @override
  ConsumerState<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<_FeedbackForm> {
  int _feeling = 3;
  bool _pain = false;
  final _notesCtrl = TextEditingController();
  final _kmCtrl    = TextEditingController();
  bool _submitting = false;

  static const _emojis = ['😫', '😓', '😐', '😊', '🤩'];

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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Feeling
          Text('HOE VOELDE HET?',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) {
              final val = i + 1;
              final selected = _feeling == val;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => setState(() => _feeling = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected ? widget.sessionColor.withOpacity(.2) : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? widget.sessionColor : AppColors.outline,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(child: Text(_emojis[i],
                        style: const TextStyle(fontSize: 24))),
                  ),
                ),
              ));
            }),
          ),

          const SizedBox(height: 16),

          // Pain
          Material(
            color: _pain ? AppColors.errorDim : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _pain = !_pain),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Icon(_pain ? Icons.check_box : Icons.check_box_outline_blank,
                      color: _pain ? AppColors.error : AppColors.muted, size: 20),
                  const SizedBox(width: 10),
                  Text('Pijn of ongemak tijdens sessie',
                      style: TextStyle(
                        fontSize: 14,
                        color: _pain ? AppColors.error : AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                      )),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 12),
          TextField(
            controller: _kmCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.onBg),
            decoration: const InputDecoration(
              labelText: 'Gelopen km (optioneel)',
              suffixText: 'km',
              prefixIcon: Icon(Icons.route_outlined, size: 18),
            ),
          ),

          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            style: const TextStyle(color: AppColors.onBg),
            decoration: const InputDecoration(
              labelText: 'Notities (optioneel)',
              hintText: 'Hoe ging het?',
              prefixIcon: Icon(Icons.notes_outlined, size: 18),
            ),
          ),

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(height: 18, width: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Sessie afronden'),
          ),
        ],
      ),
    );
  }
}
