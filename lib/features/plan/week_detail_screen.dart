import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_list_item.dart';
import 'plan_provider.dart';
import 'widgets/day_card.dart';

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

    final week = weeks[weekIndex];
    final completed = week.completedCount;
    final total = week.activeDays.length;
    final hasPrev = weekIndex > 0;
    final hasNext = weekIndex < weeks.length - 1;

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
          child: DayCard(
            day: week.days[i],
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
              fontSize: 12,
              color: AppColors.brand,
              fontWeight: FontWeight.w700)),
    );
  }
}
