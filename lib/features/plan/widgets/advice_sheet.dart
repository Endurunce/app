import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/shimmer.dart';
import '../plan_provider.dart';
import '../session_type_style.dart';

class AdviceSheet extends ConsumerStatefulWidget {
  final Day day;
  final Week week;
  final TrainingPlan plan;

  const AdviceSheet({
    super.key,
    required this.day,
    required this.week,
    required this.plan,
  });

  @override
  ConsumerState<AdviceSheet> createState() => _AdviceSheetState();
}

class _AdviceSheetState extends ConsumerState<AdviceSheet> {
  Map<String, dynamic>? _advice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdvice();
  }

  Future<void> _loadAdvice() async {
    final data = await ref.read(planProvider.notifier).getSessionAdvice(
          planId: widget.plan.id,
          weekNumber: widget.week.weekNumber,
          weekday: widget.day.weekday,
        );
    if (mounted) {
      setState(() {
        _advice = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = styleFor(widget.day.sessionType);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
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
              Center(
                  child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.outlineHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),

              Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: s.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child:
                          Text(s.emoji, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.label,
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(dayNames[widget.day.weekday],
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13)),
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
          Text(s.label, style: Theme.of(context).textTheme.titleSmall),
          if (s.paceNote.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(s.paceNote,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.onSurface)),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      if (widget.day.sessionType != 'rest') ...[
        _InfoRow(
            icon: Icons.route_outlined,
            color: AppColors.brand,
            label: 'Afstand',
            value:
                '${widget.day.effectiveKm.toStringAsFixed(1)} km'),
      ],
    ]);
  }

  List<Widget> _buildAdvice(BuildContext context) {
    final a = _advice!;
    return [
      if (a['summary'] != null)
        _AdviceBlock(
          icon: Icons.info_outline,
          color: AppColors.brand,
          title: 'Samenvatting',
          text: a['summary'] as String,
        ),
      const SizedBox(height: 12),
      if (a['goal'] != null)
        _AdviceBlock(
          icon: Icons.flag_outlined,
          color: AppColors.easy,
          title: 'Doel',
          text: a['goal'] as String,
        ),
      const SizedBox(height: 12),
      if (a['warmup'] != null)
        _AdviceBlock(
          icon: Icons.thermostat_outlined,
          color: AppColors.warning,
          title: 'Warming-up',
          text: a['warmup'] as String,
        ),
      const SizedBox(height: 12),
      if (a['main_set'] != null)
        _AdviceBlock(
          icon: Icons.directions_run_outlined,
          color: AppColors.brand,
          title: 'Hoofdset',
          text: a['main_set'] as String,
        ),
      const SizedBox(height: 12),
      if (a['cooldown'] != null)
        _AdviceBlock(
          icon: Icons.ac_unit_outlined,
          color: AppColors.longRun,
          title: 'Cooling-down',
          text: a['cooldown'] as String,
        ),
      const SizedBox(height: 16),
      if (a['go_signal'] != null || a['stop_signal'] != null)
        Row(children: [
          if (a['go_signal'] != null)
            Expanded(
                child: _SignalCard(
              color: AppColors.easy,
              icon: Icons.check_circle_outline,
              title: 'Goed teken',
              text: a['go_signal'] as String,
            )),
          if (a['go_signal'] != null && a['stop_signal'] != null)
            const SizedBox(width: 10),
          if (a['stop_signal'] != null)
            Expanded(
                child: _SignalCard(
              color: AppColors.error,
              icon: Icons.stop_circle_outlined,
              title: 'Stop signaal',
              text: a['stop_signal'] as String,
            )),
        ]),
      const SizedBox(height: 12),
      if (a['too_hard'] != null)
        _AdviceBlock(
          icon: Icons.sentiment_dissatisfied_outlined,
          color: AppColors.warning,
          title: 'Als het te zwaar is',
          text: a['too_hard'] as String,
        ),
      const SizedBox(height: 12),
      if (a['why_now'] != null)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigher,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('WAAROM NU',
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700)),
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
  const _AdviceBlock(
      {required this.icon,
      required this.color,
      required this.title,
      required this.text});

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
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: color,
                  fontWeight: FontWeight.w700)),
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
  const _SignalCard(
      {required this.color,
      required this.icon,
      required this.title,
      required this.text});

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
  const _InfoRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}
