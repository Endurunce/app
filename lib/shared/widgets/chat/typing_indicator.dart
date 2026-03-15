import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  List.generate(3, (i) => _Dot(controller: _ctrl, index: i)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final AnimationController controller;
  final int index;
  const _Dot({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.2; // 0.0, 0.2, 0.4 → intervals end at 0.6, 0.8, 1.0
    final animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(delay, delay + 0.6, curve: Curves.easeInOut),
    ));

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 7,
        height: 7,
        transform: Matrix4.translationValues(0, animation.value, 0),
        decoration: const BoxDecoration(
          color: AppColors.muted,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ToolIndicator extends StatelessWidget {
  final String toolName;
  const ToolIndicator({super.key, required this.toolName});

  static String _toolLabel(String toolName) => switch (toolName) {
        'get_active_plan' => '📊 Trainingsplan bekijken...',
        'update_plan' => '✏️ Plan aanpassen...',
        'get_profile' => '👤 Profiel ophalen...',
        'get_injuries' => '🩹 Blessures bekijken...',
        'get_strava_data' => '🏃 Strava data ophalen...',
        _ => '⚙️ $toolName...',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 40),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.brand.withValues(alpha: .6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _toolLabel(toolName),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
