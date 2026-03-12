import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/age.dart';
import 'intake_helpers.dart';

class StepPersonal extends StatelessWidget {
  final TextEditingController nameCtrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final VoidCallback onPickDob;
  final void Function(String) onGenderChanged;
  final VoidCallback onChanged;

  const StepPersonal({
    super.key,
    required this.nameCtrl,
    required this.dateOfBirth,
    required this.gender,
    required this.onPickDob,
    required this.onGenderChanged,
    required this.onChanged,
  });

  bool get _isUnderSixteen {
    if (dateOfBirth == null) return false;
    return calculateAge(dateOfBirth!) < 16;
  }

  String get _dobLabel {
    if (dateOfBirth == null) return 'Geboortedatum kiezen';
    return '${dateOfBirth!.day.toString().padLeft(2, '0')}-'
        '${dateOfBirth!.month.toString().padLeft(2, '0')}-'
        '${dateOfBirth!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
            emoji: '👤',
            title: 'Over jezelf',
            subtitle: 'We personaliseren je plan op basis van jouw profiel'),
        TextField(
          controller: nameCtrl,
          style: const TextStyle(color: AppColors.onBg),
          decoration: const InputDecoration(
            labelText: 'Voornaam',
            hintText: 'Bijv. Sanne',
            prefixIcon: Icon(Icons.person_outline, size: 18),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onPickDob,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Geboortedatum',
              prefixIcon: const Icon(Icons.cake_outlined, size: 18),
              errorText: _isUnderSixteen
                  ? 'Je moet minimaal 16 jaar oud zijn om deze app te gebruiken.'
                  : null,
            ),
            child: Text(
              _dobLabel,
              style: TextStyle(
                color: dateOfBirth == null ? AppColors.muted : AppColors.onBg,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Geslacht'),
        ChipRow(
          values: const ['male', 'female', 'other'],
          labels: const ['Man', 'Vrouw', 'Anders'],
          selected: gender,
          onSelect: onGenderChanged,
        ),
      ],
    );
  }
}
