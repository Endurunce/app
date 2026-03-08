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
  ('shoulder',   '💪 Schouder'),
  ('it_band',    '🦵 IT-band'),
];

class _ReportInjurySheet extends ConsumerStatefulWidget {
  const _ReportInjurySheet();

  @override
  ConsumerState<_ReportInjurySheet> createState() => _ReportInjurySheetState();
}

class _ReportInjurySheetState extends ConsumerState<_ReportInjurySheet> {
  final Set<String> _selectedLocations = {};
  int _severity   = 5;
  String? _side;          // 'links', 'rechts', 'beide'
  String? _painType;      // 'scherp', 'bonkend', 'stijf', 'brandend', 'trekkerig'
  String? _whenPain;      // 'alleen bij bewegen', 'constant', 'na inspanning', 'bij druk'
  String? _duration;      // '< 1 dag', '1-3 dagen', '3-7 dagen', '> 1 week'
  String? _mobility;      // 'full', 'walk_only', 'limited'
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

  bool get _canWalk => _mobility != 'limited';
  bool get _canRun  => _mobility == 'full';

  void _buildAutoDescription() {
    final parts = <String>[];
    if (_side != null)     parts.add('Kant: $_side');
    if (_painType != null) parts.add('Pijntype: $_painType');
    if (_whenPain != null) parts.add('Wanneer: $_whenPain');
    if (_duration != null) parts.add('Duur: $_duration');
    _descCtrl.text = parts.join(' · ');
  }

  Future<void> _submit() async {
    if (_selectedLocations.isEmpty || _mobility == null) return;
    setState(() => _submitting = true);

    _buildAutoDescription();

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
      maxChildSize:     0.95,
      minChildSize:     0.5,
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

              Row(
                children: [
                  Expanded(
                    child: Text('Blessure melden',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Sluiten',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Beschrijf zo nauwkeurig mogelijk',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),

              // ── Mobility ──
              _SheetSectionLabel('Mobiliteit'),
              _MobilityOption(
                label: 'Volledig lopen en hardlopen',
                selected: _mobility == 'full',
                onTap: () => setState(() => _mobility = 'full'),
              ),
              const SizedBox(height: 8),
              _MobilityOption(
                label: 'Alleen wandelen, niet hardlopen',
                selected: _mobility == 'walk_only',
                onTap: () => setState(() => _mobility = 'walk_only'),
              ),
              const SizedBox(height: 8),
              _MobilityOption(
                label: 'Moeite met lopen',
                selected: _mobility == 'limited',
                onTap: () => setState(() => _mobility = 'limited'),
              ),

              const SizedBox(height: 24),

              // ── Location chips ──
              _SheetSectionLabel('Locatie'),
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

              // ── Side selection (shown after location selected) ──
              if (_selectedLocations.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SheetSectionLabel('Kant'),
                _ChipRowSingle(
                  values: ['links', 'rechts', 'beide'],
                  labels: ['Links', 'Rechts', 'Beide'],
                  selected: _side,
                  onSelect: (v) => setState(() => _side = v),
                ),
              ],

              const SizedBox(height: 24),

              // ── Severity ──
              Row(children: [
                _SheetSectionLabel('Ernst'),
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

              const SizedBox(height: 16),

              // ── Pain type ──
              _SheetSectionLabel('Soort pijn'),
              _ChipRowSingle(
                values: ['scherp', 'bonkend', 'stijf', 'brandend', 'trekkerig'],
                labels: ['Scherp', 'Bonkend', 'Stijf', 'Brandend', 'Trekkerig'],
                selected: _painType,
                onSelect: (v) => setState(() => _painType = v),
              ),

              const SizedBox(height: 16),

              // ── When pain occurs ──
              _SheetSectionLabel('Wanneer treedt pijn op?'),
              _ChipRowSingle(
                values: [
                  'alleen bij bewegen',
                  'constant',
                  'na inspanning',
                  'bij druk/aanraking',
                ],
                labels: [
                  'Alleen bij bewegen',
                  'Constant',
                  'Na inspanning',
                  'Bij druk/aanraking',
                ],
                selected: _whenPain,
                onSelect: (v) => setState(() => _whenPain = v),
              ),

              const SizedBox(height: 16),

              // ── Duration ──
              _SheetSectionLabel('Hoe lang al?'),
              _ChipRowSingle(
                values: ['< 1 dag', '1-3 dagen', '3-7 dagen', '> 1 week'],
                labels: ['< 1 dag', '1-3 dagen', '3-7 dagen', '> 1 week'],
                selected: _duration,
                onSelect: (v) => setState(() => _duration = v),
              ),

              const SizedBox(height: 16),

              // ── Description ──
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
                onPressed: (_submitting || _selectedLocations.isEmpty || _mobility == null)
                    ? null
                    : _submit,
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

// ── Sheet helpers ──────────────────────────────────────────────────────────────

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
    );
  }
}

class _MobilityOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MobilityOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.easy.withOpacity(.12) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.easy : AppColors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: selected ? AppColors.easy : AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: selected ? AppColors.easy : AppColors.onSurface,
              ))),
        ]),
      ),
    );
  }
}

class _ChipRowSingle extends StatelessWidget {
  final List<String> values;
  final List<String> labels;
  final String? selected;
  final void Function(String) onSelect;
  const _ChipRowSingle({
    required this.values, required this.labels,
    required this.selected, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(values.length, (i) {
        final active = selected == values[i];
        return GestureDetector(
          onTap: () => onSelect(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.brand.withOpacity(.15) : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.brand : AppColors.outline,
                width: active ? 2 : 1,
              ),
            ),
            child: Text(labels[i],
                style: TextStyle(
                  fontSize: 13,
                  color: active ? AppColors.brand : AppColors.onSurface,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
        );
      }),
    );
  }
}
