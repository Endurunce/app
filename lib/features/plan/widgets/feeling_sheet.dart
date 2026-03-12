import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../plan_provider.dart';

class FeedbackForm extends ConsumerStatefulWidget {
  final Day day;
  final Week week;
  final TrainingPlan plan;
  final Color sessionColor;
  final VoidCallback onDone;

  const FeedbackForm({
    super.key,
    required this.day,
    required this.week,
    required this.plan,
    required this.sessionColor,
    required this.onDone,
  });

  @override
  ConsumerState<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<FeedbackForm> {
  int _feeling = 3;
  bool _pain = false;
  final _notesCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  bool _submitting = false;

  static const _emojis = ['😫', '😓', '😐', '😊', '🤩'];

  @override
  void dispose() {
    _notesCtrl.dispose();
    _kmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(planProvider.notifier).completeDay(
            planId: widget.plan.id,
            weekNumber: widget.week.weekNumber,
            weekday: widget.day.weekday,
            feeling: _feeling,
            pain: _pain,
            notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
            actualKm: double.tryParse(_kmCtrl.text),
          );
      widget.onDone();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Text('HOE VOELDE HET?',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) {
              final val = i + 1;
              final selected = _feeling == val;
              return Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => setState(() => _feeling = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected
                          ? widget.sessionColor.withValues(alpha: .2)
                          : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? widget.sessionColor
                            : AppColors.outline,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                        child: Text(_emojis[i],
                            style: const TextStyle(fontSize: 24))),
                  ),
                ),
              ));
            }),
          ),

          const SizedBox(height: 16),

          Material(
            color: _pain ? AppColors.errorDim : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _pain = !_pain),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Icon(
                      _pain
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: _pain ? AppColors.error : AppColors.muted,
                      size: 20),
                  const SizedBox(width: 10),
                  Text('Pijn of ongemak tijdens sessie',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            _pain ? AppColors.error : AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                      )),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 12),
          TextField(
            controller: _kmCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.onBg),
            decoration: const InputDecoration(
              labelText: 'Gelopen km (optioneel)',
              suffixText: 'km',
              prefixIcon: Icon(Icons.route_outlined, size: 18),
            ),
          ),

          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            style: const TextStyle(color: AppColors.onBg),
            decoration: const InputDecoration(
              labelText: 'Notities (optioneel)',
              hintText: 'Hoe ging het?',
              prefixIcon: Icon(Icons.notes_outlined, size: 18),
            ),
          ),

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Sessie afronden'),
          ),
        ],
      ),
    );
  }
}
