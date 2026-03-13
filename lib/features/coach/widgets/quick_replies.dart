import 'package:flutter/material.dart';

import '../../../core/coach_service.dart';
import '../../../shared/theme/app_theme.dart';

/// Horizontal scrollable row of quick-reply chips.
/// For training_days: multi-select toggle chips with confirm button.
/// For other questions: single-select chips.
class QuickRepliesBar extends StatefulWidget {
  final String questionId;
  final List<QuickReplyOption> options;
  final void Function(String value, String label) onSelect;
  /// Called for multi-select (training_days) with comma-joined values.
  final void Function(String value, String label)? onMultiConfirm;

  const QuickRepliesBar({
    super.key,
    required this.questionId,
    required this.options,
    required this.onSelect,
    this.onMultiConfirm,
  });

  @override
  State<QuickRepliesBar> createState() => _QuickRepliesBarState();
}

class _QuickRepliesBarState extends State<QuickRepliesBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final Set<String> _selected = {};

  bool get _isMultiSelect => widget.questionId == 'training_days';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onTap(QuickReplyOption option) {
    if (_isMultiSelect) {
      setState(() {
        if (_selected.contains(option.value)) {
          _selected.remove(option.value);
        } else {
          _selected.add(option.value);
        }
      });
    } else {
      final label = option.emoji != null
          ? '${option.emoji} ${option.label}'
          : option.label;
      widget.onSelect(option.value, label);
    }
  }

  void _onConfirmMulti() {
    if (_selected.length < 2) return;
    final sorted = _selected.toList()..sort();
    final value = sorted.join(',');
    final labels = sorted.map((v) {
      final opt = widget.options.firstWhere((o) => o.value == v);
      return opt.label;
    }).join(', ');
    (widget.onMultiConfirm ?? widget.onSelect)(value, labels);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.outline, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.options.map((opt) {
                    final isSelected = _selected.contains(opt.value);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _QuickReplyChip(
                        option: opt,
                        isSelected: isSelected,
                        isMultiSelect: _isMultiSelect,
                        onTap: () => _onTap(opt),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_isMultiSelect) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selected.length >= 2 ? _onConfirmMulti : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      disabledBackgroundColor: AppColors.muted.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _selected.length >= 2
                          ? 'Klaar (${_selected.length} dagen)'
                          : 'Kies minimaal 2 dagen',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final QuickReplyOption option;
  final bool isSelected;
  final bool isMultiSelect;
  final VoidCallback onTap;

  const _QuickReplyChip({
    required this.option,
    required this.isSelected,
    required this.isMultiSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasEmoji = option.emoji != null && option.emoji!.isNotEmpty;

    return Material(
      color: isSelected ? AppColors.brand : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.brand : AppColors.outline,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasEmoji) ...[
                Text(option.emoji!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
              ],
              Text(
                option.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.onBg,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
