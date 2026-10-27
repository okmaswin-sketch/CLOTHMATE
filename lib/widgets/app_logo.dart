import 'package:flutter/material.dart';
import '../app/theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 80, this.showSubtitle = true});

  final double size;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primary;
    final double hangerSize = size * 0.7;
    final double fontSize = size * 0.18;
    final double subtitleSize = size * 0.085;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(hangerSize, hangerSize),
          painter: _HangerPainter(color: color, strokeWidth: size * 0.045),
        ),
        SizedBox(height: size * 0.1),
        Text(
          'CLOTH MATE',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: fontSize * 0.08,
            height: 1.1,
          ),
        ),
        if (showSubtitle) ...[
          SizedBox(height: size * 0.03),
          Text(
            'WARDROBE ORGANIZER & MATCHER',
            style: TextStyle(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w400,
              color: color.withValues(alpha: 0.7),
              letterSpacing: subtitleSize * 0.15,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _HangerPainter extends CustomPainter {
  _HangerPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final topY = h * 0.15;
    final hookR = w * 0.18;
    final shoulderW = w * 0.42;
    final shoulderY = topY + hookR;
    final dropH = h * 0.35;

    final path = Path();

    path.moveTo(centerX - shoulderW / 2, shoulderY);
    path.arcToPoint(
      Offset(centerX, topY),
      radius: Radius.circular(hookR),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    );
    path.arcToPoint(
      Offset(centerX + shoulderW / 2, shoulderY),
      radius: Radius.circular(hookR),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    );

    path.moveTo(centerX - shoulderW / 2, shoulderY);
    path.lineTo(centerX - shoulderW / 2, shoulderY + dropH);
    path.moveTo(centerX + shoulderW / 2, shoulderY);
    path.lineTo(centerX + shoulderW / 2, shoulderY + dropH);

    final barY = shoulderY + dropH * 0.6;
    path.moveTo(centerX - shoulderW * 0.3, barY);
    path.lineTo(centerX + shoulderW * 0.3, barY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AppLogoSmall extends StatelessWidget {
  const AppLogoSmall({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return AppLogo(size: size, showSubtitle: false);
  }
}