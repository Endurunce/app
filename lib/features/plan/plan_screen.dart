import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_list_item.dart';
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
    final planState = ref.watch(planProvider);
    final injuries  = ref.watch(injuryProvider);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Builder(
          key: ValueKey('${planState.loading}_${planState.error}_${planState.plan?.id}'),
          builder: (ctx) {
            if (planState.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (planState.error == 'no_plan') {
              return _NoPlanView(onCreatePlan: () => context.go('/intake'));
            }
            if (planState.error != null) {
              return Center(
                child: Text(planState.error!,
                    style: const TextStyle(color: AppColors.error)),
              );
            }
            if (planState.plan == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _PlanView(plan: planState.plan!, injuries: injuries);
          },
        ),
      ),
    );
  }
}

// ── No plan ───────────────────────────────────────────────────────────────────

class _NoPlanView extends StatefulWidget {
  final VoidCallback onCreatePlan;
  const _NoPlanView({required this.onCreatePlan});

  @override
  State<_NoPlanView> createState() => _NoPlanViewState();
}

class _NoPlanViewState extends State<_NoPlanView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🏃', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Nog geen trainingsplan',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Maak een persoonlijk schema op basis\nvan jouw profiel en doelstelling.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: widget.onCreatePlan,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Plan aanmaken'),
                  style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Plan view ─────────────────────────────────────────────────────────────────

class _PlanView extends ConsumerWidget {
  final TrainingPlan plan;
  final List<dynamic> injuries;

  const _PlanView({required this.plan, required this.injuries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedWeeks = plan.weeks
        .where((w) => w.completedCount == w.activeDays.length && w.activeDays.isNotEmpty)
        .length;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap:     true,
          pinned:   false,
          title:    const Text('Trainingsplan'),
          actions: const [],
        ),

        // Plan header card
        SliverToBoxAdapter(
          child: AnimatedListItem(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.brand.withValues(alpha: .14),
                      AppColors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.brand.withValues(alpha: .25)),
                ),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.raceGoal.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11, letterSpacing: 2,
                          color: AppColors.brand, fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${plan.weeks.length} weken',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 2),
                      Text(
                        '$completedWeeks van ${plan.weeks.length} weken afgerond',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )),
                  _CircleProgress(completed: completedWeeks, total: plan.weeks.length),
                ]),
              ),
            ),
          ),
        ),

        // Injury banner
        if (injuries.isNotEmpty)
          SliverToBoxAdapter(
            child: AnimatedListItem(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Material(
                  color: AppColors.errorDim,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.go('/injuries'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        const Text('🩹', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${injuries.length} actieve blessure${injuries.length > 1 ? 's' : ''} — plan is aangepast',
                            style: const TextStyle(
                              color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.error),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Week list (staggered)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => AnimatedListItem(
                index: i + (injuries.isNotEmpty ? 2 : 1),
                child: _WeekCard(week: plan.weeks[i], planId: plan.id),
              ),
              childCount: plan.weeks.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Animated circle progress ───────────────────────────────────────────────────

class _CircleProgress extends StatelessWidget {
  final int completed;
  final int total;
  const _CircleProgress({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final target = total > 0 ? completed / total : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => SizedBox(
        width: 64, height: 64,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 5,
            backgroundColor: AppColors.outline,
            color: AppColors.brand,
          ),
          Text('${(value * 100).round()}%',
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onBg)),
        ]),
      ),
    );
  }
}

// ── Week card ─────────────────────────────────────────────────────────────────

class _WeekCard extends StatelessWidget {
  final Week week;
  final String planId;

  const _WeekCard({required this.week, required this.planId});

  @override
  Widget build(BuildContext context) {
    final completed   = week.completedCount;
    final total       = week.activeDays.length;
    final isFullyDone = total > 0 && completed == total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/plan/week/${week.weekNumber}'),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isFullyDone ? AppColors.easy.withValues(alpha: .4) : AppColors.outline,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  Expanded(child: Row(children: [
                    Text('Week ${week.weekNumber}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 10),
                    _Badge(week.phaseLabel, AppColors.brand),
                    if (week.isRecovery) ...[
                      const SizedBox(width: 6),
                      _Badge('Herstel', AppColors.longRun),
                    ],
                    if (isFullyDone) ...[
                      const SizedBox(width: 6),
                      _Badge('✓', AppColors.easy),
                    ],
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${week.targetKm.round()} km',
                        style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: AppColors.brand)),
                    Text('doelkilometrage',
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ]),

                const SizedBox(height: 14),

                // Day pills
                Row(
                  children: week.days.map((day) {
                    if (day.sessionType == 'rest') {
                      return Expanded(child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.restDim,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(dayNames[day.weekday],
                            style: const TextStyle(
                              fontSize: 9, color: AppColors.rest,
                              fontWeight: FontWeight.w600))),
                      ));
                    }
                    final s = styleFor(day.sessionType);
                    return Expanded(child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 40,
                      decoration: BoxDecoration(
                        color: day.completed ? s.color.withValues(alpha: .3) : s.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: day.completed
                            ? Border.all(color: s.color.withValues(alpha: .6))
                            : null,
                      ),
                      child: Center(child: Text(s.emoji,
                          style: const TextStyle(fontSize: 17))),
                    ));
                  }).toList(),
                ),

                // Animated progress bar
                if (total > 0) ...[
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: total > 0 ? completed / total : 0.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(value: value, minHeight: 3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$completed / $total sessies',
                          style: Theme.of(context).textTheme.bodySmall),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
