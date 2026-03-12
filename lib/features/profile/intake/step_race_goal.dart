import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/duration_picker.dart';
import 'intake_helpers.dart';

class StepRaceGoal extends StatelessWidget {
  final String? raceGoal;
  final double? raceGoalCustomKm;
  final DateTime? raceDate;
  final String? terrain;
  final Duration? raceTimeGoal;
  final double weeklyKm;
  final void Function(String, double?) onRaceGoalChanged;
  final void Function(double) onCustomKmChanged;
  final void Function(DateTime?) onRaceDateChanged;
  final void Function(String) onTerrainChanged;
  final void Function(Duration?) onRaceTimeGoalChanged;

  const StepRaceGoal({
    super.key,
    required this.raceGoal,
    required this.raceGoalCustomKm,
    required this.raceDate,
    required this.terrain,
    required this.raceTimeGoal,
    required this.weeklyKm,
    required this.onRaceGoalChanged,
    required this.onCustomKmChanged,
    required this.onRaceDateChanged,
    required this.onTerrainChanged,
    required this.onRaceTimeGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final raceDateStr = raceDate == null
        ? null
        : '${raceDate!.day.toString().padLeft(2, '0')}-'
            '${raceDate!.month.toString().padLeft(2, '0')}-${raceDate!.year}';
    final weeksUntil = raceDate == null
        ? null
        : raceDate!.difference(DateTime.now()).inDays ~/ 7;
    final peakKm = weeklyKm * 1.4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
            emoji: '🏔️',
            title: 'Race & doelstelling',
            subtitle: 'Waarvoor train je?'),

        const SectionLabel('Eerste stappen'),
        ChipRow(
          values: const ['five_km', 'ten_km'],
          labels: const ['5 km', '10 km'],
          selected: raceGoal,
          onSelect: (v) => onRaceGoalChanged(v, null),
        ),
        const SizedBox(height: 16),

        const SectionLabel('Marathon'),
        ChipRow(
          values: const ['half_marathon', 'marathon', 'sub3_marathon', 'sub4_marathon'],
          labels: const ['Halve marathon', 'Marathon', 'Sub-3 marathon', 'Sub-4 marathon'],
          selected: raceGoal,
          onSelect: (v) => onRaceGoalChanged(v, null),
        ),
        const SizedBox(height: 16),

        const SectionLabel('Ultra'),
        ChipRow(
          values: const ['fifty_km', 'hundred_km'],
          labels: const ['50 km', '100 km'],
          selected: raceGoal,
          onSelect: (v) => onRaceGoalChanged(v, null),
        ),
        const SizedBox(height: 16),

        const SectionLabel('Eigen afstand'),
        GestureDetector(
          onTap: () => onRaceGoalChanged('custom', raceGoalCustomKm ?? 42.195),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: raceGoal == 'custom'
                  ? AppColors.brand.withValues(alpha: .15)
                  : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: raceGoal == 'custom' ? AppColors.brand : AppColors.outline,
                width: raceGoal == 'custom' ? 2 : 1,
              ),
            ),
            child: Text('Eigen afstand invoeren',
                style: TextStyle(
                  fontSize: 13,
                  color: raceGoal == 'custom' ? AppColors.brand : AppColors.onSurface,
                  fontWeight: raceGoal == 'custom' ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
        ),
        if (raceGoal == 'custom') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Slider(
                value: raceGoalCustomKm ?? 42.0,
                min: 5,
                max: 250,
                divisions: 49,
                onChanged: onCustomKmChanged,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${(raceGoalCustomKm ?? 42).round()} km',
                  style: const TextStyle(
                      color: AppColors.brand, fontWeight: FontWeight.w800)),
            ),
          ]),
        ],
        const SizedBox(height: 20),

        const SectionLabel('Racedatum'),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: raceDate ?? DateTime.now().add(const Duration(days: 90)),
              firstDate: DateTime.now().add(const Duration(days: 14)),
              lastDate: DateTime.now().add(const Duration(days: 730)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: Theme.of(ctx).colorScheme.copyWith(
                    primary: AppColors.brand,
                    surface: AppColors.surfaceHigher,
                  ),
                ),
                child: child!,
              ),
            );
            onRaceDateChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: raceDate != null ? AppColors.brand : AppColors.outline,
                width: raceDate != null ? 2 : 1,
              ),
            ),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined,
                  size: 18,
                  color: raceDate != null ? AppColors.brand : AppColors.muted),
              const SizedBox(width: 10),
              Text(
                raceDateStr ?? 'Kies een datum',
                style: TextStyle(
                  fontSize: 14,
                  color: raceDate != null ? AppColors.onBg : AppColors.muted,
                ),
              ),
            ]),
          ),
        ),

        if (raceDate != null && weeksUntil != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brand.withValues(alpha: .25)),
            ),
            child: Row(children: [
              const Icon(Icons.preview_outlined, size: 16, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                'Preview: $weeksUntil weken schema, '
                'piekkilometrage ~${peakKm.round()} km/week',
                style: const TextStyle(fontSize: 12, color: AppColors.brand, height: 1.4),
              )),
            ]),
          ),
        ],

        const SizedBox(height: 20),
        const SectionLabel('Ondergrond'),
        ChipRow(
          values: const ['road', 'mixed', 'trail'],
          labels: const ['Weg', 'Mixed', 'Trail'],
          selected: terrain,
          onSelect: onTerrainChanged,
        ),

        if (raceGoal != null) ...[
          const SizedBox(height: 20),
          const SectionLabel('Tijdsdoelstelling (optioneel)'),
          DurationField(
            label: 'Streeftijd',
            value: raceTimeGoal,
            onTap: () => showDurationPicker(
                context: context,
                initial: raceTimeGoal,
                onPicked: onRaceTimeGoalChanged),
          ),
        ],
      ],
    );
  }
}
