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
        backgroundColor: AppColors.terra,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Melden'),
        onPressed: () => _showReportSheet(context),
      ),
      body: injuries.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: injuries.length,
              itemBuilder: (ctx, i) => _InjuryCard(injury: injuries[i]),
            ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ReportInjurySheet(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text('🎉', style: TextStyle(fontSize: 48)),
        SizedBox(height: 12),
        Text('Geen actieve blessures',
            style: TextStyle(fontFamily: 'Georgia', fontSize: 18,
                fontWeight: FontWeight.w700, color: AppColors.ink)),
        SizedBox(height: 6),
        Text('Blijf zo doorgaan!',
            style: TextStyle(color: AppColors.inkMid)),
      ],
    ),
  );
}

class _InjuryCard extends ConsumerWidget {
  final Injury injury;
  const _InjuryCard({required this.injury});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severityColor = injury.severity >= 7 ? AppColors.terra
        : injury.severity >= 4 ? AppColors.sand
        : AppColors.moss;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Severity indicator
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: severityColor.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('${injury.severity}',
                    style: TextStyle(fontFamily: 'Georgia', fontSize: 18,
                        fontWeight: FontWeight.w700, color: severityColor)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ernst ${injury.severity}/10',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                Text(injury.reportedAt,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkLight)),
              ],
            )),
            if (!injury.canRun)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.terraDim,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('Niet kunnen lopen',
                    style: TextStyle(fontSize: 10, color: AppColors.terra, fontWeight: FontWeight.w600)),
              ),
          ]),

          if (injury.description != null) ...[
            const SizedBox(height: 10),
            Text(injury.description!,
                style: const TextStyle(fontSize: 13, color: AppColors.inkMid)),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.moss,
                side: const BorderSide(color: AppColors.moss),
              ),
              onPressed: () async {
                await ref.read(injuryProvider.notifier).resolve(injury.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Blessure gemarkeerd als hersteld ✓')),
                  );
                }
              },
              child: const Text('Markeren als hersteld'),
            ),
          ),
        ],
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
  ('hamstring',  '🦿 Hamstring'),
  ('calf',       '🦵 Kuit'),
  ('foot',       '🦶 Voet'),
  ('ankle',      '🦶 Enkel'),
  ('lower_back', '🔙 Rug'),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20,
          MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Blessure melden',
                style: TextStyle(fontFamily: 'Georgia', fontSize: 20,
                    fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 20),

            // Location chips
            _sectionLabel('Locatie (meerdere mogelijk)'),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _locations.map((loc) {
                final selected = _selectedLocations.contains(loc.$1);
                return FilterChip(
                  label: Text(loc.$2),
                  selected: selected,
                  onSelected: (_) => setState(() =>
                      selected ? _selectedLocations.remove(loc.$1)
                               : _selectedLocations.add(loc.$1)),
                  selectedColor: AppColors.terraDim,
                  checkmarkColor: AppColors.terra,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            _sectionLabel('Ernst: $_severity / 10'),
            Slider(
              value: _severity.toDouble(),
              min: 1, max: 10, divisions: 9,
              activeColor: _severity >= 7 ? AppColors.terra
                  : _severity >= 4 ? AppColors.sand : AppColors.moss,
              onChanged: (v) => setState(() => _severity = v.round()),
            ),

            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: CheckboxListTile(
                title: const Text('Kan lopen', style: TextStyle(fontSize: 13)),
                value: _canWalk,
                activeColor: AppColors.moss,
                onChanged: (v) => setState(() => _canWalk = v ?? true),
                contentPadding: EdgeInsets.zero,
              )),
              Expanded(child: CheckboxListTile(
                title: const Text('Kan hardlopen', style: TextStyle(fontSize: 13)),
                value: _canRun,
                activeColor: AppColors.moss,
                onChanged: (v) => setState(() => _canRun = v ?? false),
                contentPadding: EdgeInsets.zero,
              )),
            ]),

            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Omschrijving (optioneel)',
                hintText: 'Wanneer begon het? Wat doet pijn?',
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.terra),
                onPressed: (_submitting || _selectedLocations.isEmpty) ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Blessure melden'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(),
        style: const TextStyle(fontSize: 10, letterSpacing: 2, color: AppColors.inkLight)),
  );
}
