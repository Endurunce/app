import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_list_item.dart';
import 'strava_provider.dart';

class StravaScreen extends ConsumerStatefulWidget {
  const StravaScreen({super.key});

  @override
  ConsumerState<StravaScreen> createState() => _StravaScreenState();
}

class _StravaScreenState extends ConsumerState<StravaScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(stravaProvider.notifier).checkStatus());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stravaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Strava')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.waitingForCallback
              ? _WaitingView(
                  onCancel: () => ref.read(stravaProvider.notifier).cancelConnect(),
                )
              : state.connected
                  ? _ConnectedView(state: state)
                  : _DisconnectedView(
                      error: state.error,
                      onConnect: () => ref.read(stravaProvider.notifier).startConnect(),
                    ),
    );
  }
}

// ── Disconnected ───────────────────────────────────────────────────────────────

class _DisconnectedView extends StatelessWidget {
  final String? error;
  final VoidCallback onConnect;

  const _DisconnectedView({required this.error, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFC4C02).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text('🏅', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Koppel Strava',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Verbind je Strava-account om je activiteiten automatisch te synchroniseren.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onConnect,
              icon: const Text('🏃', style: TextStyle(fontSize: 16)),
              label: const Text('Verbinden met Strava'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFC4C02),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Waiting for callback ───────────────────────────────────────────────────────

class _WaitingView extends StatelessWidget {
  final VoidCallback onCancel;
  const _WaitingView({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Wachten op Strava...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Autoriseer de app in je browser. Deze pagina wordt automatisch bijgewerkt.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextButton(onPressed: onCancel, child: const Text('Annuleren')),
        ],
      ),
    );
  }
}

// ── Connected view ─────────────────────────────────────────────────────────────

class _ConnectedView extends ConsumerWidget {
  final StravaState state;
  const _ConnectedView({required this.state});

  static const _typeEmoji = {
    'Run':      '🏃',
    'TrailRun': '🥾',
    'Hike':     '🥾',
    'Walk':     '🚶',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Athlete card
        AnimatedListItem(
          index: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(children: [
              if (state.avatarUrl != null)
                ClipOval(
                  child: Image.network(
                    state.avatarUrl!,
                    width: 52, height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _AvatarPlaceholder(),
                  ),
                )
              else
                const _AvatarPlaceholder(),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.displayName ?? 'Strava-atleet',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.easy, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('Verbonden',
                        style: TextStyle(fontSize: 12, color: AppColors.easy, fontWeight: FontWeight.w600)),
                  ]),
                ],
              )),
              const Text('🏅', style: TextStyle(fontSize: 28)),
            ]),
          ),
        ),

        const SizedBox(height: 20),

        if (state.activities.isEmpty) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('🏃', style: TextStyle(fontSize: 40)),
                SizedBox(height: 12),
                Text('Geen activiteiten gevonden',
                    style: TextStyle(color: AppColors.onSurface, fontSize: 14)),
              ]),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Activiteiten laden'),
            onPressed: () => ref.read(stravaProvider.notifier).loadActivities(),
          ),
        ] else ...[
          AnimatedListItem(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${state.activities.length} ACTIVITEITEN',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
              ),
            ),
          ),
          ...state.activities.asMap().entries.map((e) => AnimatedListItem(
            index: e.key + 2,
            child: _ActivityCard(activity: e.value, typeEmoji: _typeEmoji),
          )),
        ],
      ],
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        shape: BoxShape.circle,
      ),
      child: const Center(child: Icon(Icons.person_outline, color: AppColors.muted, size: 28)),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final StravaActivity activity;
  final Map<String, String> typeEmoji;
  const _ActivityCard({required this.activity, required this.typeEmoji});

  @override
  Widget build(BuildContext context) {
    final emoji = typeEmoji[activity.type] ?? '🏃';
    final date  = activity.startDate;
    final dateStr = '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(dateStr,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${activity.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppColors.brand)),
            const SizedBox(height: 2),
            Text(activity.durationFormatted,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ]),
      ),
    );
  }
}
