import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import 'intake_helpers.dart';

class StepExperience extends StatelessWidget {
  final String? runningYears;
  final double weeklyKm;
  final void Function(String) onRunningYearsChanged;
  final void Function(double) onWeeklyKmChanged;

  const StepExperience({
    super.key,
    required this.runningYears,
    required this.weeklyKm,
    required this.onRunningYearsChanged,
    required this.onWeeklyKmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
            emoji: '🏃',
            title: 'Loopervaring',
            subtitle: 'Hoeveel ervaring heb je als hardloper?'),
        const SectionLabel('Hoe lang loop je al?'),
        ChipRow(
          values: const [
            'less_than_two_years',
            'two_to_five_years',
            'five_to_ten_years',
            'more_than_ten_years',
          ],
          labels: const ['< 2 jaar', '2-5 jaar', '5-10 jaar', '10+ jaar'],
          selected: runningYears,
          onSelect: onRunningYearsChanged,
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const SectionLabel('Weekkilometrage'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${weeklyKm.round()} km/week',
                style: const TextStyle(
                    color: AppColors.brand, fontWeight: FontWeight.w800)),
          ),
        ]),
        Row(children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 20, color: AppColors.muted),
            onPressed: weeklyKm > 0
                ? () => onWeeklyKmChanged((weeklyKm - 5).clamp(0, 150))
                : null,
          ),
          Expanded(
            child: Slider(
              value: weeklyKm,
              min: 0,
              max: 150,
              divisions: 30,
              onChanged: onWeeklyKmChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20, color: AppColors.muted),
            onPressed: weeklyKm < 150
                ? () => onWeeklyKmChanged((weeklyKm + 5).clamp(0, 150))
                : null,
          ),
        ]),
      ],
    );
  }
}
