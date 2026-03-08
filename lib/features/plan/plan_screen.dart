import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../injury/injury_provider.dart';
import 'plan_provider.dart';
import 'session_type_style.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(planProvider.notifier).loadActivePlan();
      ref.read(injuryProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final planState   = ref.watch(planProvider);
    final injuries    = ref.watch(injuryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Endurance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.healing_outlined),
            tooltip: 'Blessures',
            onPressed: () => context.push('/injuries'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Uitloggen',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Builder(builder: (ctx) {
        if (planState.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.moss));
        }

        if (planState.error == 'no_plan') {
          return _NoPlanView(onCreatePlan: () => context.go('/intake'));
        }

        if (planState.error != null) {
          return Center(child: Text(planState.error!, style: const TextStyle(color: AppColors.terra)));
        }

        final plan = planState.plan!;
        return _PlanView(plan: plan, injuries: injuries);
      }),
    );
  }
}

class _NoPlanView extends StatelessWidget {
  final VoidCallback onCreatePlan;
  const _NoPlanView({required this.onCreatePlan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏃', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Nog geen trainingsplan',
                style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text('Maak een persoonlijk schema op basis van jouw profiel en doelstelling.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkMid, fontSize: 14)),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onCreatePlan,
              child: const Text('Plan aanmaken'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanView extends StatelessWidget {
  final TrainingPlan plan;
  final List<dynamic> injuries;

  const _PlanView({required this.plan, required this.injuries});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Active injury banner
        if (injuries.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.terraDim,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.terra.withOpacity(.3)),
              ),
              child: Row(children: [
                const Text('🩹', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  '${injuries.length} actieve blessure${injuries.length > 1 ? 's' : ''} — plan is aangepast.',
                  style: const TextStyle(color: AppColors.terra, fontSize: 13, fontWeight: FontWeight.w500),
                )),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  onPressed: () => context.push('/injuries'),
                  child: const Text('Bekijk', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
          ),

        // Week list
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _WeekCard(week: plan.weeks[i], planId: plan.id),
              childCount: plan.weeks.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  final Week week;
  final String planId;

  const _WeekCard({required this.week, required this.planId});

  @override
  Widget build(BuildContext context) {
    final completed = week.completedCount;
    final total     = week.activeDays.length;
    final progress  = total > 0 ? completed / total : 0.0;

    return GestureDetector(
      onTap: () => context.push('/plan/week/${week.weekNumber}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Week ${week.weekNumber}',
                      style: const TextStyle(fontFamily: 'Georgia', fontSize: 16,
                          fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Row(children: [
                    _phaseBadge(week.phaseLabel),
                    if (week.isRecovery) ...[
                      const SizedBox(width: 6),
                      _badge('Herstel', AppColors.sky, AppColors.skyDim),
                    ],
                  ]),
                ]),
              ),
              Text('${week.targetKm.round()} km',
                  style: const TextStyle(fontFamily: 'Georgia', fontSize: 20,
                      fontWeight: FontWeight.w700, color: AppColors.moss)),
            ]),

            const SizedBox(height: 12),

            // Day pills
            Row(
              children: week.days.map((day) {
                if (day.sessionType == 'rest') {
                  return Expanded(child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(dayNames[day.weekday],
                        style: const TextStyle(fontSize: 10, color: AppColors.inkLight))),
                  ));
                }
                final s = styleFor(day.sessionType);
                return Expanded(child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 36,
                  decoration: BoxDecoration(
                    color: day.completed ? s.color : s.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: s.color.withOpacity(.4)),
                  ),
                  child: Center(child: Text(s.emoji,
                      style: const TextStyle(fontSize: 16))),
                ));
              }).toList(),
            ),

            // Progress bar
            if (total > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.border,
                  color: AppColors.moss,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text('$completed / $total sessies voltooid',
                  style: const TextStyle(fontSize: 11, color: AppColors.inkLight)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _phaseBadge(String label) => _badge(label, AppColors.moss, AppColors.mossDim);

  Widget _badge(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );
}
