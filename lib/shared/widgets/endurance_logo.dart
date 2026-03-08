import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EnduranceLogo extends StatelessWidget {
  final String? subtitle;
  const EnduranceLogo({super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'JOUW TRAININGSPARTNER',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 6,
            color: AppColors.moss,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Endurance',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        Container(
          width: 32,
          height: 2,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.moss,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: AppColors.inkLight),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
