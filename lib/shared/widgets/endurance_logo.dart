import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EnduranceLogo extends StatelessWidget {
  final String? subtitle;
  final double iconSize;
  const EnduranceLogo({super.key, this.subtitle, this.iconSize = 56});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brand, AppColors.brandDeep],
            ),
            borderRadius: BorderRadius.circular(iconSize * 0.22),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: .35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CustomPaint(painter: _RunnerPainter()),
        ),
        const SizedBox(height: 20),

        // Wordmark
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Endur',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onBg,
                  letterSpacing: -1.0,
                ),
              ),
              TextSpan(
                text: 'unce',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
        ),

        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _RunnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07;

    // Head
    canvas.drawCircle(Offset(w * 0.56, h * 0.17), w * 0.09, p..style = PaintingStyle.fill);
    p.style = PaintingStyle.stroke;

    // Body
    canvas.drawLine(Offset(w * 0.53, h * 0.26), Offset(w * 0.44, h * 0.51), p);

    // Arms
    final armPath = Path()
      ..moveTo(w * 0.50, h * 0.31)
      ..lineTo(w * 0.64, h * 0.26)
      ..lineTo(w * 0.70, h * 0.35);
    canvas.drawPath(armPath, p);
    final arm2 = Path()
      ..moveTo(w * 0.50, h * 0.31)
      ..lineTo(w * 0.36, h * 0.40)
      ..lineTo(w * 0.30, h * 0.33);
    canvas.drawPath(arm2, p);

    // Legs
    final leg1 = Path()
      ..moveTo(w * 0.44, h * 0.51)
      ..lineTo(w * 0.57, h * 0.67)
      ..lineTo(w * 0.51, h * 0.82);
    canvas.drawPath(leg1, p);
    final leg2 = Path()
      ..moveTo(w * 0.44, h * 0.51)
      ..lineTo(w * 0.35, h * 0.66)
      ..lineTo(w * 0.22, h * 0.60);
    canvas.drawPath(leg2, p);

    // Calf bandage
    p
      ..strokeWidth = w * 0.055
      ..color = Colors.white.withValues(alpha: .8);
    canvas.drawLine(
      Offset(w * 0.545, h * 0.735),
      Offset(w * 0.575, h * 0.695),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
