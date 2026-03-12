import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool sending;
  final void Function(String) onSend;
  const InputBar({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  static const _maxChars = 1000;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() =>
      setState(() => _charCount = widget.controller.text.length);

  @override
  Widget build(BuildContext context) {
    final nearLimit = _charCount > (_maxChars * 0.8).round();
    final overLimit = _charCount > _maxChars;
    final canSend = !widget.sending && !overLimit && _charCount > 0;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          MediaQuery.of(context).viewInsets.bottom + 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    style: const TextStyle(
                        color: AppColors.onBg, fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    maxLength: _maxChars,
                    buildCounter: (_,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: canSend ? widget.onSend : null,
                    decoration: const InputDecoration(
                      hintText: 'Stel een vraag aan je coach...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: canSend ? AppColors.brand : AppColors.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: canSend
                        ? () => widget.onSend(widget.controller.text)
                        : null,
                    child: Center(
                      child: widget.sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            if (nearLimit)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 52),
                child: Text(
                  '$_charCount / $_maxChars',
                  style: TextStyle(
                    fontSize: 11,
                    color: overLimit ? AppColors.error : AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
