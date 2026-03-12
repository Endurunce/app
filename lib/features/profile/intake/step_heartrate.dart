import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/age.dart';
import 'intake_helpers.dart';

class StepHeartrate extends StatelessWidget {
  final DateTime? dateOfBirth;
  final bool hrAuto;
  final TextEditingController maxHrCtrl;
  final TextEditingController restHrCtrl;
  final List<TextEditingController> zoneLoCtrls;
  final List<TextEditingController> zoneHiCtrls;
  final void Function(bool) onHrAutoChanged;
  final VoidCallback onRecalcZones;
  final VoidCallback onChanged;

  const StepHeartrate({
    super.key,
    required this.dateOfBirth,
    required this.hrAuto,
    required this.maxHrCtrl,
    required this.restHrCtrl,
    required this.zoneLoCtrls,
    required this.zoneHiCtrls,
    required this.onHrAutoChanged,
    required this.onRecalcZones,
    required this.onChanged,
  });

  static const _zoneNames = [
    'Z1 Herstel',
    'Z2 Aerobe basis',
    'Z3 Aerobe drempel',
    'Z4 Anaerobe drempel',
    'Z5 VO₂max'
  ];
  static const _zoneColors = [
    Color(0xFF7bc67e),
    Color(0xFF5a7a52),
    Color(0xFFc49a5a),
    Color(0xFFb85c3a),
    Color(0xFFc0392b)
  ];

  @override
  Widget build(BuildContext context) {
    final dob = dateOfBirth ?? DateTime(DateTime.now().year - 30);
    final age = calculateAge(dob);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
            emoji: '❤️',
            title: 'Hartslagzones',
            subtitle: 'Optioneel — helpt ons je trainingsintensiteit te calibreren'),

        MobilityOption(
          label: 'Automatisch berekenen (220 − leeftijd)',
          subtitle: 'Max HR = ${220 - age} bpm',
          selected: hrAuto,
          onTap: () => onHrAutoChanged(true),
        ),
        const SizedBox(height: 8),
        MobilityOption(
          label: 'Zelf invoeren',
          subtitle: 'Vul je gemeten max hartslag in',
          selected: !hrAuto,
          onTap: () => onHrAutoChanged(false),
        ),

        if (!hrAuto) ...[
          const SizedBox(height: 16),
          TextField(
            controller: maxHrCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.onBg),
            decoration: const InputDecoration(
              labelText: 'Max hartslag (bpm)',
              hintText: '190',
              prefixIcon: Icon(Icons.favorite_outline, size: 18),
            ),
            onChanged: (_) => onChanged(),
          ),
        ],

        const SizedBox(height: 14),
        TextField(
          controller: restHrCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.onBg),
          decoration: const InputDecoration(
            labelText: 'Rusthartslag (bpm)',
            hintText: '55',
            prefixIcon: Icon(Icons.bedtime_outlined, size: 18),
          ),
          onChanged: (_) => onChanged(),
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('JOUW ZONES',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                )),
            TextButton.icon(
              onPressed: onRecalcZones,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Herbereken', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(
            5,
            (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration:
                          BoxDecoration(color: _zoneColors[i], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 130,
                      child: Text(_zoneNames[i],
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.onSurface)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: zoneLoCtrls[i],
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13, color: AppColors.onBg),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          hintText: 'van',
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('–', style: TextStyle(color: AppColors.muted)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: zoneHiCtrls[i],
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13, color: AppColors.onBg),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          hintText: 'tot',
                          suffixText: 'bpm',
                          suffixStyle: TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                  ]),
                )),
      ],
    );
  }
}
