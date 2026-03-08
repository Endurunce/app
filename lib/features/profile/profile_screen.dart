import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_list_item.dart';
import '../auth/auth_provider.dart';
import '../plan/plan_provider.dart';
import '../strava/strava_provider.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileProvider.notifier).load();
      ref.read(stravaProvider.notifier).checkStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth    = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);
    final plan    = ref.watch(planProvider);
    final strava  = ref.watch(stravaProvider);

    // Statistieken uit het plan
    int totalSessions = 0;
    int completedSessions = 0;
    if (plan.plan != null) {
      for (final week in plan.plan!.weeks) {
        final active = week.activeDays;
        totalSessions    += active.length;
        completedSessions += active.where((d) => d.completed).length;
      }
    }

    final displayName = profile.profile?.name
        ?? auth.displayName
        ?? auth.email?.split('@').first
        ?? 'Hardloper';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar / header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                    colors: [AppColors.brand, Color(0xFF1a6b4a)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Avatar(
                          avatarUrl: strava.avatarUrl,
                          name:      displayName,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (auth.email != null)
                          Text(
                            auth.email!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .75),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Planvoortgang ─────────────────────────────────────────
                if (plan.plan != null) ...[
                  AnimatedListItem(
                    index: 0,
                    child: _SectionCard(
                      title: 'Trainingsplan',
                      children: [
                        if (profile.profile != null) ...[
                          _InfoRow(
                            icon:  profile.profile!.raceGoalEmoji,
                            label: 'Doel',
                            value: profile.profile!.raceGoalLabel,
                          ),
                          if (profile.profile!.raceDate != null)
                            _InfoRow(
                              icon:  '📅',
                              label: 'Racedag',
                              value: _formatDate(profile.profile!.raceDate!),
                            ),
                          _InfoRow(
                            icon:  '🏔️',
                            label: 'Terrein',
                            value: profile.profile!.terrainLabel,
                          ),
                          const Divider(height: 24),
                        ],
                        _ProgressRow(
                          completed: completedSessions,
                          total:     totalSessions,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Persoonlijk ───────────────────────────────────────────
                if (profile.profile != null)
                  AnimatedListItem(
                    index: 1,
                    child: _SectionCard(
                      title: 'Profiel',
                      children: [
                        _InfoRow(icon: '🎂', label: 'Leeftijd',   value: '${profile.profile!.age} jaar'),
                        _InfoRow(icon: '⚧',  label: 'Geslacht',   value: profile.profile!.genderLabel),
                        _InfoRow(icon: '🏃', label: 'Ervaring',   value: profile.profile!.runningYearsLabel),
                        _InfoRow(icon: '📏', label: 'Weekkm',     value: '${profile.profile!.weeklyKm.round()} km'),
                      ],
                    ),
                  ),

                if (profile.profile != null) const SizedBox(height: 12),

                // ── Strava ────────────────────────────────────────────────
                AnimatedListItem(
                  index: 2,
                  child: _SectionCard(
                    title: 'Strava',
                    children: [
                      if (strava.loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (strava.connected)
                        Row(children: [
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.easy, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strava.displayName ?? 'Strava verbonden',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onBg,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.read(stravaProvider.notifier).loadActivities(),
                            child: const Text('Activiteiten'),
                          ),
                        ])
                      else ...[
                        Text(
                          'Verbind Strava om activiteiten automatisch te synchroniseren.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (strava.waitingForCallback)
                          Column(children: [
                            const LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(
                              'Wachten op autorisatie...',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            TextButton(
                              onPressed: () => ref.read(stravaProvider.notifier).cancelConnect(),
                              child: const Text('Annuleren'),
                            ),
                          ])
                        else
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => ref.read(stravaProvider.notifier).startConnect(),
                              icon: const Text('🏅', style: TextStyle(fontSize: 14)),
                              label: const Text('Verbinden met Strava'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFC4C02),
                              ),
                            ),
                          ),
                        if (strava.error != null) ...[
                          const SizedBox(height: 8),
                          Text(strava.error!,
                              style: const TextStyle(color: AppColors.error, fontSize: 12)),
                        ],
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Account ───────────────────────────────────────────────
                AnimatedListItem(
                  index: 3,
                  child: _SectionCard(
                    title: 'Account',
                    children: [
                      _ActionRow(
                        icon:  Icons.edit_outlined,
                        label: 'Nieuw trainingsplan aanmaken',
                        onTap: () => context.go('/intake'),
                      ),
                      const Divider(height: 20),
                      _ActionRow(
                        icon:  Icons.logout_outlined,
                        label: 'Uitloggen',
                        color: AppColors.error,
                        onTap: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      const months = ['jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
                      'jul', 'aug', 'sep', 'okt', 'nov', 'dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  const _Avatar({required this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          width: 64, height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Initials(name: name),
        ),
      );
    }
    return _Initials(name: name);
  }
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .5), width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppColors.onBg, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final int completed;
  final int total;
  const _ProgressRow({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? completed / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('🏁', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text('Voortgang', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const Spacer(),
          Text(
            '$completed / $total sessies',
            style: const TextStyle(color: AppColors.onBg, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.outline,
            valueColor: const AlwaysStoppedAnimation(AppColors.brand),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.onBg;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 20, color: c),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w500)),
          const Spacer(),
          Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
        ]),
      ),
    );
  }
}
