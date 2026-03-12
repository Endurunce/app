import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_list_item.dart';
import '../../shared/widgets/shimmer.dart';
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

    final weeks = plan.weeks;
    final weekIndex = weeks.indexWhere((w) => w.weekNumber == weekNumber);
    if (weekIndex < 0) {
      return const Scaffold(body: Center(child: Text('Week niet gevonden')));
    }

    final week      = weeks[weekIndex];
    final completed = week.completedCount;
    final total     = week.activeDays.length;
    final hasPrev   = weekIndex > 0;
    final hasNext   = weekIndex < weeks.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Week $weekNumber'),
        actions: [
          if (hasPrev)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Vorige week',
              onPressed: () => context.pushReplacement(
                '/plan/week/${weeks[weekIndex - 1].weekNumber}'),
            ),
          if (hasNext)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Volgende week',
              onPressed: () => context.pushReplacement(
                '/plan/week/${weeks[weekIndex + 1].weekNumber}'),
            ),
        ],
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
        itemBuilder: (ctx, i) => AnimatedListItem(
          index: i,
          child: _DayCard(
            day:  week.days[i],
            week: week,
            plan: plan,
          ),
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
        color: AppColors.brand.withValues(alpha: .15),
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
  bool _expanded    = false;
  bool _uncompleting = false;

  @override
  Widget build(BuildContext context) {
    final day    = widget.day;
    final s      = styleFor(day.sessionType);
    final isRest = day.sessionType == 'rest';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                // Session icon → tap opens session detail sheet
                GestureDetector(
                  onTap: isRest ? null : () => _showSessionDetail(context),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: s.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(s.emoji,
                        style: const TextStyle(fontSize: 24))),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + info → tap opens session detail sheet
                Expanded(
                  child: GestureDetector(
                    onTap: isRest ? null : () => _showSessionDetail(context),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
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
                    ),
                  ),
                ),

                // km display
                if (!isRest && day.sessionType != 'cross') ...[
                  const SizedBox(width: 8),
                  Text('${day.effectiveKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: s.color)),
                  const SizedBox(width: 8),
                ],

                // ✓ / ○ button
                if (!isRest)
                  GestureDetector(
                    onTap: day.completed
                        ? _uncomplete
                        : () => setState(() => _expanded = !_expanded),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation, curve: Curves.easeOutBack),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: day.completed
                          ? Container(
                              key: const ValueKey('done'),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.easy.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _uncompleting
                                  ? const SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(
                                        color: AppColors.easy, strokeWidth: 2))
                                  : const Text('✓',
                                      style: TextStyle(
                                        fontSize: 16, color: AppColors.easy,
                                        fontWeight: FontWeight.w800)),
                            )
                          : Container(
                              key: const ValueKey('open'),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Icon(
                                _expanded
                                    ? Icons.expand_less
                                    : Icons.radio_button_unchecked,
                                size: 18, color: AppColors.muted,
                              ),
                            ),
                    ),
                  ),
              ]),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _expanded && !day.completed
                  ? _FeedbackForm(
                      day:          widget.day,
                      week:         widget.week,
                      plan:         widget.plan,
                      sessionColor: s.color,
                      onDone:       () => setState(() => _expanded = false),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uncomplete() async {
    setState(() => _uncompleting = true);
    try {
      await ref.read(planProvider.notifier).uncompleteDay(
        planId:     widget.plan.id,
        weekNumber: widget.week.weekNumber,
        weekday:    widget.day.weekday,
      );
    } finally {
      if (mounted) setState(() => _uncompleting = false);
    }
  }

  void _showSessionDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionDetailSheet(
        day:  widget.day,
        week: widget.week,
        plan: widget.plan,
      ),
    );
  }
}

// ── Session detail sheet ───────────────────────────────────────────────────────

class _SessionDetailSheet extends ConsumerStatefulWidget {
  final Day day;
  final Week week;
  final TrainingPlan plan;

  const _SessionDetailSheet({
    required this.day,
    required this.week,
    required this.plan,
  });

  @override
  ConsumerState<_SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends ConsumerState<_SessionDetailSheet> {
  Map<String, dynamic>? _advice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdvice();
  }

  Future<void> _loadAdvice() async {
    final data = await ref.read(planProvider.notifier).getSessionAdvice(
      planId:     widget.plan.id,
      weekNumber: widget.week.weekNumber,
      weekday:    widget.day.weekday,
    );
    if (mounted) setState(() { _advice = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final s = styleFor(widget.day.sessionType);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize:     0.95,
      minChildSize:     0.4,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // Handle
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.outlineHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),

              // Header
              Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: s.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(s.emoji,
                      style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.label,
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(dayNames[widget.day.weekday],
                        style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                )),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),

              const SizedBox(height: 20),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _loading
                    ? Column(
                        key: const ValueKey('skeleton'),
                        children: _buildSkeleton(),
                      )
                    : _advice == null
                        ? KeyedSubtree(
                            key: const ValueKey('fallback'),
                            child: _buildFallback(context, s),
                          )
                        : Column(
                            key: const ValueKey('advice'),
                            children: _buildAdvice(context),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSkeleton() => [
    _SkeletonBlock(height: 60),
    const SizedBox(height: 12),
    _SkeletonBlock(height: 80),
    const SizedBox(height: 12),
    _SkeletonBlock(height: 80),
    const SizedBox(height: 12),
    _SkeletonBlock(height: 60),
  ];

  Widget _buildFallback(BuildContext context, SessionStyle s) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: s.bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.label,
              style: Theme.of(context).textTheme.titleSmall),
          if (s.paceNote.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(s.paceNote,
                style: const TextStyle(fontSize: 13, color: AppColors.onSurface)),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      if (widget.day.sessionType != 'rest') ...[
        _InfoRow(icon: Icons.route_outlined, color: AppColors.brand,
            label: 'Afstand', value: '${widget.day.effectiveKm.toStringAsFixed(1)} km'),
      ],
    ]);
  }

  List<Widget> _buildAdvice(BuildContext context) {
    final a = _advice!;
    return [
      // Summary
      if (a['summary'] != null)
        _AdviceBlock(
          icon: Icons.info_outline,
          color: AppColors.brand,
          title: 'Samenvatting',
          text: a['summary'] as String,
        ),

      const SizedBox(height: 12),

      // Goal
      if (a['goal'] != null)
        _AdviceBlock(
          icon: Icons.flag_outlined,
          color: AppColors.easy,
          title: 'Doel',
          text: a['goal'] as String,
        ),

      const SizedBox(height: 12),

      // Warmup
      if (a['warmup'] != null)
        _AdviceBlock(
          icon: Icons.thermostat_outlined,
          color: AppColors.warning,
          title: 'Warming-up',
          text: a['warmup'] as String,
        ),

      const SizedBox(height: 12),

      // Main set
      if (a['main_set'] != null)
        _AdviceBlock(
          icon: Icons.directions_run_outlined,
          color: AppColors.brand,
          title: 'Hoofdset',
          text: a['main_set'] as String,
        ),

      const SizedBox(height: 12),

      // Cooldown
      if (a['cooldown'] != null)
        _AdviceBlock(
          icon: Icons.ac_unit_outlined,
          color: AppColors.longRun,
          title: 'Cooling-down',
          text: a['cooldown'] as String,
        ),

      const SizedBox(height: 16),

      // Go / Stop signals side by side
      if (a['go_signal'] != null || a['stop_signal'] != null)
        Row(children: [
          if (a['go_signal'] != null)
            Expanded(child: _SignalCard(
              color: AppColors.easy,
              icon: Icons.check_circle_outline,
              title: 'Goed teken',
              text: a['go_signal'] as String,
            )),
          if (a['go_signal'] != null && a['stop_signal'] != null)
            const SizedBox(width: 10),
          if (a['stop_signal'] != null)
            Expanded(child: _SignalCard(
              color: AppColors.error,
              icon: Icons.stop_circle_outlined,
              title: 'Stop signaal',
              text: a['stop_signal'] as String,
            )),
        ]),

      const SizedBox(height: 12),

      // If too hard
      if (a['too_hard'] != null)
        _AdviceBlock(
          icon: Icons.sentiment_dissatisfied_outlined,
          color: AppColors.warning,
          title: 'Als het te zwaar is',
          text: a['too_hard'] as String,
        ),

      const SizedBox(height: 12),

      // Why now
      if (a['why_now'] != null)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigher,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('WAAROM NU',
                style: TextStyle(
                  fontSize: 10, letterSpacing: 1.5,
                  color: AppColors.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(a['why_now'] as String,
                style: const TextStyle(
                  fontSize: 13, color: AppColors.muted, height: 1.5)),
          ]),
        ),

      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close, size: 16),
        label: const Text('Sluiten'),
      ),
    ];
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double height;
  const _SkeletonBlock({required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      width: double.infinity,
      height: height,
      borderRadius: 12,
    );
  }
}

class _AdviceBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  const _AdviceBlock({required this.icon, required this.color,
      required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title.toUpperCase(),
              style: TextStyle(
                fontSize: 10, letterSpacing: 1.5,
                color: color, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Text(text,
            style: const TextStyle(
              fontSize: 13, color: AppColors.onSurface, height: 1.5)),
      ]),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String text;
  const _SignalCard({required this.color, required this.icon,
      required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(title,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 6),
        Text(text,
            style: const TextStyle(
              fontSize: 12, color: AppColors.onSurface, height: 1.4)),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.color,
      required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      const Spacer(),
      Text(value,
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    ]);
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
  int _feeling    = 3;
  bool _pain      = false;
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
      decoration: const BoxDecoration(
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
              final val      = i + 1;
              final selected = _feeling == val;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => setState(() => _feeling = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected
                          ? widget.sessionColor.withValues(alpha: .2)
                          : AppColors.surfaceHigh,
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
