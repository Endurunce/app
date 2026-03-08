import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import 'injury_provider.dart';

class InjuryScreen extends ConsumerStatefulWidget {
  const InjuryScreen({super.key});

  @override
  ConsumerState<InjuryScreen> createState() => _InjuryScreenState();
}

class _InjuryScreenState extends ConsumerState<InjuryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(injuryProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final injuries = ref.watch(injuryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blessures')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Melden'),
        onPressed: () => _showReportSheet(context),
      ),
      body: injuries.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: injuries.length,
              itemBuilder: (ctx, i) => _InjuryCard(injury: injuries[i]),
            ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ReportInjurySheet(),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.easy.withOpacity(.12),
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

// ── Injury card ───────────────────────────────────────────────────────────────

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
          border: Border.all(color: severityColor.withOpacity(.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(.12),
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
                side: BorderSide(color: AppColors.easy.withOpacity(.4)),
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Markeren als hersteld'),
              onPressed: () async {
                await ref.read(injuryProvider.notifier).resolve(injury.id);
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

// ── Report sheet ──────────────────────────────────────────────────────────────

const _locations = [
  ('knee',       '🦵 Knie'),
  ('achilles',   '🦶 Achilles'),
  ('shin',       '🦷 Scheenbeen'),
  ('hip',        '🫀 Heup'),
  ('hamstring',  '🏃 Hamstring'),
  ('calf',       '🦵 Kuit'),
  ('foot',       '🦶 Voet'),
  ('ankle',      '🦶 Enkel'),
  ('lower_back', '🔙 Onderrug'),
];

class _ReportInjurySheet extends ConsumerStatefulWidget {
  const _ReportInjurySheet();

  @override
  ConsumerState<_ReportInjurySheet> createState() => _ReportInjurySheetState();
}

class _ReportInjurySheetState extends ConsumerState<_ReportInjurySheet> {
  final Set<String> _selectedLocations = {};
  int _severity = 5;
  bool _canWalk = true;
  bool _canRun  = false;
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Color get _severityColor => _severity >= 7
      ? AppColors.error
      : _severity >= 4
          ? AppColors.warning
          : AppColors.easy;

  Future<void> _submit() async {
    if (_selectedLocations.isEmpty) return;
    setState(() => _submitting = true);

    final msg = await ref.read(injuryProvider.notifier).report(
      locations:   _selectedLocations.toList(),
      severity:    _severity,
      canWalk:     _canWalk,
      canRun:      _canRun,
      description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
    );

    if (mounted) {
      Navigator.pop(context);
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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

              Text('Blessure melden',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Beschrijf zo nauwkeurig mogelijk',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),

              // Location chips
              Text('LOCATIE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _locations.map((loc) {
                  final selected = _selectedLocations.contains(loc.$1);
                  return FilterChip(
                    label: Text(loc.$2),
                    selected: selected,
                    onSelected: (_) => setState(() => selected
                        ? _selectedLocations.remove(loc.$1)
                        : _selectedLocations.add(loc.$1)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              Row(children: [
                Text('ERNST',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _severityColor.withOpacity(.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$_severity / 10',
                      style: TextStyle(
                        color: _severityColor, fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _severityColor,
                  thumbColor:       _severityColor,
                ),
                child: Slider(
                  value: _severity.toDouble(),
                  min: 1, max: 10, divisions: 9,
                  onChanged: (v) => setState(() => _severity = v.round()),
                ),
              ),

              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _CheckOption(
                  label: 'Kan lopen',
                  value: _canWalk,
                  onChanged: (v) => setState(() => _canWalk = v),
                )),
                const SizedBox(width: 10),
                Expanded(child: _CheckOption(
                  label: 'Kan hardlopen',
                  value: _canRun,
                  onChanged: (v) => setState(() => _canRun = v),
                )),
              ]),

              const SizedBox(height: 14),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.onBg),
                decoration: const InputDecoration(
                  labelText: 'Omschrijving (optioneel)',
                  hintText: 'Wanneer begon het? Wat doet pijn?',
                  prefixIcon: Icon(Icons.notes_outlined, size: 18),
                ),
              ),

              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: (_submitting || _selectedLocations.isEmpty) ? null : _submit,
                icon: _submitting
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.report_outlined, size: 18),
                label: const Text('Blessure melden'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CheckOption extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CheckOption({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value ? AppColors.easy.withOpacity(.15) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppColors.easy : AppColors.outline,
          ),
        ),
        child: Row(children: [
          Icon(value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: value ? AppColors.easy : AppColors.muted),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: value ? AppColors.easy : AppColors.onSurface,
                fontWeight: FontWeight.w500,
              )),
        ]),
      ),
    );
  }
}
