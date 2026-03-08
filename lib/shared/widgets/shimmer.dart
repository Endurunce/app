import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated shimmer placeholder for loading states.
class Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const Shimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pos;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _pos = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pos,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              AppColors.surfaceHigh,
              AppColors.surfaceHigher,
              AppColors.surfaceHigh,
            ],
            stops: [
              (_pos.value - 0.4).clamp(0.0, 1.0),
              _pos.value.clamp(0.0, 1.0),
              (_pos.value + 0.4).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }
}
