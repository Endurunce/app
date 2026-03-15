import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../duration_picker.dart';
import 'chat_view.dart';

/// Renders the appropriate input widget based on [inputType]:
/// - chips / null: horizontal scrollable single-select chips
/// - multi_chips: toggleable multi-select chips + confirm button
/// - date_picker: opens a native date picker
/// - number: shows a number text field
/// - duration_picker: shows HH:MM:SS duration input
/// - text: shows a regular text field (focused)
class QuickRepliesBar extends StatefulWidget {
  final String questionId;
  final List<QuickReplyOption> options;
  final String? inputType;
  final void Function(String value, String label) onSelect;

  const QuickRepliesBar({
    super.key,
    required this.questionId,
    required this.options,
    this.inputType,
    required this.onSelect,
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
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  bool get _isMultiSelect => widget.inputType == 'multi_chips';

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

    // Auto-focus text/number fields after build
    if (widget.inputType == 'text' || widget.inputType == 'number') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChipTap(QuickReplyOption option) {
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
    final dayNames = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
    final labels = sorted.map((v) {
      final idx = int.tryParse(v);
      return idx != null && idx < dayNames.length ? dayNames[idx] : v;
    }).join(', ');
    widget.onSelect(value, labels);
  }

  Future<void> _showDatePicker() async {
    if (!mounted) return;
    final now = DateTime.now();
    final isRaceDate = widget.questionId == 'race_date';

    final picked = await showDatePicker(
      context: context,
      initialDate: isRaceDate ? now.add(const Duration(days: 90)) : DateTime(1990, 1, 1),
      firstDate: isRaceDate ? now : DateTime(1920),
      lastDate: isRaceDate ? DateTime(2030) : now,
      locale: const Locale('nl', 'NL'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.brand,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      final label = '${picked.day}-${picked.month}-${picked.year}';
      widget.onSelect(formatted, '📅 $label');
    }
  }

  void _submitText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || !mounted) return;
    widget.onSelect(text, text);
    _textCtrl.clear();
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
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.inputType) {
      case 'date_picker':
        return _buildDatePickerButton();
      case 'number':
        return _buildNumberInput();
      case 'duration_picker':
        return _buildDurationInput();
      case 'text':
        return _buildTextInput();
      case 'multi_chips':
        return _buildMultiChips();
      default:
        return _buildSingleChips();
    }
  }

  Widget _buildSingleChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.options.map((opt) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _QuickReplyChip(
            option: opt,
            isSelected: false,
            onTap: () => _onChipTap(opt),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMultiChips() {
    return Column(
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
                  onTap: () => _onChipTap(opt),
                ),
              );
            }).toList(),
          ),
        ),
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
    );
  }

  Widget _buildDatePickerButton() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _showDatePicker,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('Kies een datum'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        // Also show any chip options (like "skip")
        ...widget.options.map((opt) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _QuickReplyChip(
            option: opt,
            isSelected: false,
            onTap: () => _onChipTap(opt),
          ),
        )),
      ],
    );
  }

  Widget _buildNumberInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textCtrl,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            style: const TextStyle(color: AppColors.onBg),
            decoration: InputDecoration(
              hintText: widget.questionId == 'weekly_km' ? 'km per week' : 'Voer een getal in',
              hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.6)),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.outline),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              suffixIcon: IconButton(
                icon: Icon(Icons.send, color: AppColors.brand),
                onPressed: _submitText,
              ),
            ),
            onSubmitted: (_) => _submitText(),
          ),
        ),
        // Also show any chip options (like "skip")
        ...widget.options.map((opt) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _QuickReplyChip(
            option: opt,
            isSelected: false,
            onTap: () => _onChipTap(opt),
          ),
        )),
      ],
    );
  }

  Future<void> _showDurationPicker() async {
    await showDurationPicker(
      context: context,
      onPicked: (duration) {
        if (duration == null || !mounted) return;
        final h = duration.inHours;
        final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
        final value = '$h:$m:$s';
        final label = h > 0 ? '$h u $m min $s sec' : '$m:$s';
        widget.onSelect(value, '⏱ $label');
      },
    );
  }

  Widget _buildDurationInput() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _showDurationPicker,
            icon: const Icon(Icons.timer_outlined, size: 18),
            label: const Text('Kies een tijd'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        ...widget.options.map((opt) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _QuickReplyChip(
            option: opt,
            isSelected: false,
            onTap: () => _onChipTap(opt),
          ),
        )),
      ],
    );
  }

  Widget _buildTextInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textCtrl,
            focusNode: _focusNode,
            style: const TextStyle(color: AppColors.onBg),
            decoration: InputDecoration(
              hintText: 'Typ hier...',
              hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.6)),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.outline),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              suffixIcon: IconButton(
                icon: Icon(Icons.send, color: AppColors.brand),
                onPressed: _submitText,
              ),
            ),
            onSubmitted: (_) => _submitText(),
          ),
        ),
        ...widget.options.map((opt) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _QuickReplyChip(
            option: opt,
            isSelected: false,
            onTap: () => _onChipTap(opt),
          ),
        )),
      ],
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final QuickReplyOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickReplyChip({
    required this.option,
    required this.isSelected,
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
