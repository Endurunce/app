import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SuggestionBar extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  const SuggestionBar({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: suggestions
              .map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onTap(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.outlineHigh),
                        ),
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
