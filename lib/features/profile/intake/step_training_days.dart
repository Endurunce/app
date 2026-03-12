import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import 'intake_helpers.dart';

class StepTrainingDays extends StatelessWidget {
  final Set<int> trainingDays;
  final Map<int, int> dayDurations;
  final int? longRunDay;
  final bool addStrength;
  final Set<int> strengthDays;
  final void Function(int) onToggleTrainingDay;
  final void Function(int, int) onDayDurationChanged;
  final void Function(int?) onLongRunDayChanged;
  final void Function(bool) onAddStrengthChanged;
  final void Function(int) onToggleStrengthDay;

  const StepTrainingDays({
    super.key,
    required this.trainingDays,
    required this.dayDurations,
    required this.longRunDay,
    required this.addStrength,
    required this.strengthDays,
    required this.onToggleTrainingDay,
    required this.onDayDurationChanged,
    required this.onLongRunDayChanged,
    required this.onAddStrengthChanged,
    required this.onToggleStrengthDay,
  });

  static const _dayLabels = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
  static const _dayLabelsFull = [
    'Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrijdag', 'Zaterdag', 'Zondag'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
            emoji: '📅',
            title: 'Trainingsdagen',
            subtitle: 'Op welke dagen wil je trainen? (min. 2 dagen)'),
        Row(
          children: List.generate(7, (i) {
            final selected = trainingDays.contains(i);
            return Expanded(
                child: GestureDetector(
              onTap: () => onToggleTrainingDay(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brand.withValues(alpha: .2)
                      : AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.brand : AppColors.outline,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Center(
                    child: Text(_dayLabels[i],
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? AppColors.brand : AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ))),
              ),
            ));
          }),
        ),
        if (trainingDays.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionLabel('Max. duur per dag'),
          ...(trainingDays.toList()..sort()).map((d) {
            final mins = dayDurations[d] ?? 60;
            final isLong = d == longRunDay;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(_dayLabelsFull[d],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLong ? AppColors.longRun : AppColors.onBg,
                        )),
                    if (isLong) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.longRun.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Lange duurloop',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.longRun,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                          '${mins ~/ 60 > 0 ? '${mins ~/ 60}u ' : ''}${mins % 60 > 0 || mins < 60 ? '${mins % 60}m' : ''}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  Slider(
                    value: mins.toDouble(),
                    min: 30,
                    max: 240,
                    divisions: 14,
                    onChanged: (v) => onDayDurationChanged(d, v.round()),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const SectionLabel('Welke dag is je lange duurloop?'),
          DropdownButtonFormField<int>(
            value: trainingDays.contains(longRunDay) ? longRunDay : null,
            dropdownColor: AppColors.surfaceHigher,
            style: const TextStyle(color: AppColors.onBg, fontSize: 14),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.flag_outlined, size: 18),
              hintText: 'Kies een dag',
            ),
            items: (trainingDays.toList()..sort())
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(_dayLabelsFull[d]),
                    ))
                .toList(),
            onChanged: onLongRunDayChanged,
          ),
        ],

        // Strength training
        const SizedBox(height: 28),
        const SectionLabel('Krachttraining'),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => onAddStrengthChanged(!addStrength),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: addStrength
                  ? AppColors.brand.withValues(alpha: .12)
                  : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: addStrength ? AppColors.brand : AppColors.outline,
                width: addStrength ? 2 : 1,
              ),
            ),
            child: Row(children: [
              Icon(Icons.fitness_center,
                  size: 20, color: addStrength ? AppColors.brand : AppColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Krachttraining toevoegen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: addStrength ? AppColors.brand : AppColors.onBg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Krachttraining naast je hardloopschema',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(
                addStrength ? Icons.check_circle : Icons.circle_outlined,
                color: addStrength ? AppColors.brand : AppColors.muted,
                size: 22,
              ),
            ]),
          ),
        ),

        if (addStrength) ...[
          const SizedBox(height: 16),
          const Text(
            'Op welke dag(en) wil je krachttrainen?',
            style: TextStyle(fontSize: 13, color: AppColors.onSurface),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (i) {
              final selected = strengthDays.contains(i);
              return Expanded(
                  child: GestureDetector(
                onTap: () => onToggleStrengthDay(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brand.withValues(alpha: .2)
                        : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.brand : AppColors.outline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                      child: Text(_dayLabels[i],
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? AppColors.brand : AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ))),
                ),
              ));
            }),
          ),
        ],
      ],
    );
  }
}
