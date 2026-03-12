import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/duration_picker.dart';
import 'intake_helpers.dart';

class StepPerformance extends StatelessWidget {
  final Duration? time10k;
  final Duration? timeHalf;
  final Duration? timeMarathon;
  final void Function(Duration?) onTime10kChanged;
  final void Function(Duration?) onTimeHalfChanged;
  final void Function(Duration?) onTimeMarathonChanged;

  const StepPerformance({
    super.key,
    required this.time10k,
    required this.timeHalf,
    required this.timeMarathon,
    required this.onTime10kChanged,
    required this.onTimeHalfChanged,
    required this.onTimeMarathonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
            emoji: '🏅',
            title: 'Prestaties',
            subtitle: 'Optioneel — sla over als je geen persoonlijke records hebt'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.muted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Deze informatie helpt ons je trainingsintensite nauwkeuriger te berekenen.',
                style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        DurationField(
          label: '10 km tijd (optioneel)',
          value: time10k,
          onTap: () => showDurationPicker(
              context: context, initial: time10k, onPicked: onTime10kChanged),
        ),
        const SizedBox(height: 14),
        DurationField(
          label: 'Halve marathon tijd (optioneel)',
          value: timeHalf,
          onTap: () => showDurationPicker(
              context: context, initial: timeHalf, onPicked: onTimeHalfChanged),
        ),
        const SizedBox(height: 14),
        DurationField(
          label: 'Marathon tijd (optioneel)',
          value: timeMarathon,
          onTap: () => showDurationPicker(
              context: context, initial: timeMarathon, onPicked: onTimeMarathonChanged),
        ),
      ],
    );
  }
}
