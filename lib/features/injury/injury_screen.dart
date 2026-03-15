import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../plan/plan_provider.dart';
import 'injury_provider.dart';

class InjuryScreen extends ConsumerStatefulWidget {
  const InjuryScreen({super.key});

  @override
  ConsumerState<InjuryScreen> createState() => _InjuryScreenState();
}

class _InjuryScreenState extends ConsumerState<InjuryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(injuryProvider.notifier).load();
      ref.read(injuryHistoryProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blessures'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Actief'),
            Tab(text: 'Geschiedenis'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Melden'),
        onPressed: () => _openReportChat(context),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ActiveTab(),
          _HistoryTab(),
        ],
      ),
    );
  }

  void _openReportChat(BuildContext context) {
    context.push('/injury-report').then((_) {
      // Refresh active injuries after the chat screen returns.
      if (mounted) ref.read(injuryProvider.notifier).load();
    });
  }
}

// ── Active tab ────────────────────────────────────────────────────────────────

class _ActiveTab extends ConsumerWidget {
  const _ActiveTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final injuries = ref.watch(injuryProvider);

    if (injuries.isEmpty) return const _EmptyActive();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: injuries.length,
      itemBuilder: (ctx, i) => _InjuryCard(injury: injuries[i]),
    );
  }
}

// ── History tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(injuryHistoryProvider);

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📋', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text('Geen blessuregeschiedenis',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Gemelde blessures verschijnen hier.',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: state.items.length,
      itemBuilder: (ctx, i) => _HistoryCard(item: state.items[i]),
    );
  }
}

// ── History card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Injury item;
  const _HistoryCard({required this.item});

  Color get _severityColor => item.severity >= 7
      ? AppColors.error
      : item.severity >= 4
          ? AppColors.warning
          : AppColors.easy;

  String _locationLabel(String loc) {
    const labels = {
      'knee':       'Knie',
      'achilles':   'Achilles',
      'shin':       'Scheenbeen',
      'hip':        'Heup',
      'hamstring':  'Hamstring',
      'calf':       'Kuit',
      'foot':       'Voet',
      'ankle':      'Enkel',
      'lower_back': 'Onderrug',
      'shoulder':   'Schouder',
      'it_band':    'IT-band',
    };
    return labels[loc] ?? loc;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor = item.isResolved ? AppColors.easy : AppColors.warning;
    final resolvedLabel = item.isResolved ? 'Hersteld' : 'Herstellende';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _severityColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('${item.severity}',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: _severityColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.locations.map(_locationLabel).join(', '),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text('Gemeld: ${item.reportedAt}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: resolvedColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(resolvedLabel,
                    style: TextStyle(
                      fontSize: 11, color: resolvedColor,
                      fontWeight: FontWeight.w700)),
              ),
            ]),

            if (item.resolvedAt != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.easy),
                const SizedBox(width: 4),
                Text('Hersteld op ${item.resolvedAt}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.easy)),
              ]),
            ],

            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(item.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyActive extends StatelessWidget {
  const _EmptyActive();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.easy.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🎉', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Geen actieve blessures',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Blijf zo doorgaan!',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ── Active injury card ────────────────────────────────────────────────────────

class _InjuryCard extends ConsumerWidget {
  final Injury injury;
  const _InjuryCard({required this.injury});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severityColor = injury.severity >= 7
        ? AppColors.error
        : injury.severity >= 4
            ? AppColors.warning
            : AppColors.easy;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: severityColor.withValues(alpha: .25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text('${injury.severity}',
                      style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: severityColor)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ernst ${injury.severity}/10',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(injury.reportedAt,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              )),
              if (!injury.canRun)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Niet lopen',
                      style: TextStyle(
                        fontSize: 11, color: AppColors.error,
                        fontWeight: FontWeight.w700)),
                ),
            ]),

            if (injury.description != null) ...[
              const SizedBox(height: 10),
              Text(injury.description!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.easy,
                side: BorderSide(color: AppColors.easy.withValues(alpha: .4)),
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Markeren als hersteld'),
              onPressed: () async {
                await ref.read(injuryProvider.notifier).resolve(injury.id);
                await ref.read(injuryHistoryProvider.notifier).load();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Blessure gemarkeerd als hersteld ✓')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
