import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable duration picker dialog (h:mm:ss wheel).
Future<void> showDurationPicker({
  required BuildContext context,
  Duration? initial,
  required void Function(Duration?) onPicked,
}) async {
  final init = initial ?? const Duration(hours: 0, minutes: 30);
  int selH = init.inHours.clamp(0, 9);
  int selM = init.inMinutes.remainder(60);
  int selS = init.inSeconds.remainder(60);

  final FixedExtentScrollController hCtrl =
      FixedExtentScrollController(initialItem: selH);
  final FixedExtentScrollController mCtrl =
      FixedExtentScrollController(initialItem: selM);
  final FixedExtentScrollController sCtrl =
      FixedExtentScrollController(initialItem: selS);

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tijd invoeren',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.onBg)),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: const [
                Expanded(
                    child: Center(
                        child: Text('uur',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600)))),
                SizedBox(width: 8),
                Expanded(
                    child: Center(
                        child: Text('min',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600)))),
                SizedBox(width: 8),
                Expanded(
                    child: Center(
                        child: Text('sec',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600)))),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.outline),
                      ),
                    ),
                    Row(children: [
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: hCtrl,
                          itemExtent: 44,
                          diameterRatio: 1.4,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) =>
                              setDialogState(() => selH = i),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 10,
                            builder: (_, i) => Center(
                              child: Text('$i',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: selH == i
                                        ? AppColors.brand
                                        : AppColors.onSurface,
                                  )),
                            ),
                          ),
                        ),
                      ),
                      const Text(':',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onBg)),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: mCtrl,
                          itemExtent: 44,
                          diameterRatio: 1.4,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) =>
                              setDialogState(() => selM = i),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 60,
                            builder: (_, i) => Center(
                              child: Text(i.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: selM == i
                                        ? AppColors.brand
                                        : AppColors.onSurface,
                                  )),
                            ),
                          ),
                        ),
                      ),
                      const Text(':',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onBg)),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: sCtrl,
                          itemExtent: 44,
                          diameterRatio: 1.4,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) =>
                              setDialogState(() => selS = i),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 60,
                            builder: (_, i) => Center(
                              child: Text(i.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: selS == i
                                        ? AppColors.brand
                                        : AppColors.onSurface,
                                  )),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onPicked(null);
            },
            child:
                const Text('Wissen', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onPicked(
                  Duration(hours: selH, minutes: selM, seconds: selS));
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );

  hCtrl.dispose();
  mCtrl.dispose();
  sCtrl.dispose();
}
