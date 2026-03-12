import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import 'intake_helpers.dart';

class StepHealth extends StatelessWidget {
  final String? sleep;
  final TextEditingController complaintsCtrl;
  final Set<String> previousInjuries;
  final void Function(String) onSleepChanged;
  final void Function(String) onToggleInjury;

  const StepHealth({
    super.key,
    required this.sleep,
    required this.complaintsCtrl,
    required this.previousInjuries,
    required this.onSleepChanged,
    required this.onToggleInjury,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
            emoji: '💤',
            title: 'Gezondheid & herstel',
            subtitle: 'Dit helpt ons je belastbaarheid goed in te schatten'),

        const SectionLabel('Gemiddelde slaap per nacht'),
        ChipRow(
          values: const ['less_than_six', 'six_to_seven', 'seven_to_eight', 'more_than_eight'],
          labels: const ['< 6 uur', '6-7 uur', '7-8 uur', '> 8 uur'],
          selected: sleep,
          onSelect: onSleepChanged,
        ),

        const SizedBox(height: 24),
        TextField(
          controller: complaintsCtrl,
          maxLines: 3,
          style: const TextStyle(color: AppColors.onBg),
          decoration: const InputDecoration(
            labelText: 'Huidige klachten of pijnpunten (optioneel)',
            hintText: 'Beschrijf eventuele pijn of ongemakken...',
            prefixIcon: Icon(Icons.notes_outlined, size: 18),
          ),
        ),

        const SizedBox(height: 20),
        const SectionLabel('Eerdere blessures (optioneel)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Knie', 'Achilles', 'Scheenbeen', 'Heup',
            'Hamstring', 'Kuit', 'Voet', 'Enkel', 'Onderrug',
          ]
              .map((loc) {
                final selected = previousInjuries.contains(loc);
                return FilterChip(
                  label: Text(loc),
                  selected: selected,
                  onSelected: (_) => onToggleInjury(loc),
                );
              })
              .toList(),
        ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.easy.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.easy.withValues(alpha: .3)),
          ),
          child: const Row(children: [
            Text('✅', style: TextStyle(fontSize: 20)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Je persoonlijke trainingsschema wordt direct gegenereerd op basis van je profiel.',
                style: TextStyle(fontSize: 13, color: AppColors.onSurface, height: 1.4),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
