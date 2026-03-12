import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../plan_provider.dart';
import '../session_type_style.dart';
import 'advice_sheet.dart';
import 'feeling_sheet.dart';

class DayCard extends ConsumerStatefulWidget {
  final Day day;
  final Week week;
  final TrainingPlan plan;

  const DayCard({super.key, required this.day, required this.week, required this.plan});

  @override
  ConsumerState<DayCard> createState() => _DayCardState();
}

class _DayCardState extends ConsumerState<DayCard> {
  bool _expanded = false;
  bool _uncompleting = false;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final s = styleFor(day.sessionType);
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
                GestureDetector(
                  onTap: isRest ? null : () => _showSessionDetail(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: s.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                        child: Text(s.emoji, style: const TextStyle(fontSize: 24))),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: isRest ? null : () => _showSessionDetail(context),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dayNames[day.weekday].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600)),
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
                if (!isRest && day.sessionType != 'cross') ...[
                  const SizedBox(width: 8),
                  Text('${day.effectiveKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: s.color)),
                  const SizedBox(width: 8),
                ],
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.easy.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _uncompleting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          color: AppColors.easy, strokeWidth: 2))
                                  : const Text('✓',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.easy,
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
                                size: 18,
                                color: AppColors.muted,
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
                  ? FeedbackForm(
                      day: widget.day,
                      week: widget.week,
                      plan: widget.plan,
                      sessionColor: s.color,
                      onDone: () => setState(() => _expanded = false),
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
            planId: widget.plan.id,
            weekNumber: widget.week.weekNumber,
            weekday: widget.day.weekday,
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
      builder: (_) => AdviceSheet(
        day: widget.day,
        week: widget.week,
        plan: widget.plan,
      ),
    );
  }
}
