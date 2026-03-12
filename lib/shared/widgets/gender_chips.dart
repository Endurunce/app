import 'package:flutter/material.dart';

/// Reusable gender selection chips row.
class GenderChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const GenderChips({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const options = [('male', 'Man'), ('female', 'Vrouw'), ('other', 'Anders')];
    return Row(
      children: options.map((o) {
        final isSelected = selected == o.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(o.$2),
            selected: isSelected,
            onSelected: (_) => onSelect(o.$1),
          ),
        );
      }).toList(),
    );
  }
}
