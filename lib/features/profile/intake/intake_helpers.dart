import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

/// Tappable field showing a Duration as h:mm:ss (or placeholder if empty).
class DurationField extends StatelessWidget {
  final String label;
  final Duration? value;
  final VoidCallback onTap;

  const DurationField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  String get _display {
    if (value == null) return 'Kiezen…';
    final h = value!.inHours;
    final m = value!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = value!.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.timer_outlined, size: 18),
          suffixIcon: value != null
              ? const Icon(Icons.edit_outlined, size: 16, color: AppColors.muted)
              : null,
        ),
        child: Text(
          _display,
          style: TextStyle(
            color: value == null ? AppColors.muted : AppColors.onBg,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class StepHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const StepHeader({super.key, required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ])),
      ]),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
    );
  }
}

class ChipRow extends StatelessWidget {
  final List<String> values;
  final List<String> labels;
  final String? selected;
  final void Function(String) onSelect;
  const ChipRow({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(values.length, (i) {
        final active = selected == values[i];
        return GestureDetector(
          onTap: () => onSelect(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.brand.withValues(alpha: .15) : AppColors.surfaceHigh,
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

class MobilityOption extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  const MobilityOption({
    super.key,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand.withValues(alpha: .12) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
            color: selected ? AppColors.brand : AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.brand : AppColors.onBg,
                  )),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          )),
        ]),
      ),
    );
  }
}

/// Format Duration as "h:mm:ss" or null if empty.
String? formatDuration(Duration? d) {
  if (d == null) return null;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}
