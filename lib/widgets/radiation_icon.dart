import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Símbolo ☢ de radiación dibujado con CustomPainter.
/// Usado en splash (animado) y drawer (estático).
class RadiationIcon extends StatelessWidget {
  final double size;
  final Color color;
  final Color glowColor;
  final double glowBlur;

  const RadiationIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.glowColor = const Color(0x00000000),
    this.glowBlur = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: RadiationPainter(
        color: color,
        glowColor: glowColor,
        glowBlur: glowBlur,
      ),
    );
  }
}

class RadiationPainter extends CustomPainter {
  final Color color;
  final Color glowColor;
  final double glowBlur;

  const RadiationPainter({
    required this.color,
    this.glowColor = const Color(0x00000000),
    this.glowBlur = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill;

    final paint = Paint()..color = color..style = PaintingStyle.fill;

    void drawSymbol(Paint p) {
      canvas.drawCircle(Offset(cx, cy), size.width * 0.10, p);

      for (int i = 0; i < 3; i++) {
        final angle = (i * 2 * math.pi / 3) - math.pi / 2;
        final path = Path();
        final innerR = size.width * 0.155;
        final outerR = size.width * 0.42;
        const sweep = 0.9;
        final startAngle = angle - sweep / 2;
        final endAngle = angle + sweep / 2;

        path.moveTo(cx + innerR * math.cos(startAngle), cy + innerR * math.sin(startAngle));
        path.lineTo(cx + outerR * math.cos(startAngle), cy + outerR * math.sin(startAngle));
        path.arcToPoint(
          Offset(cx + outerR * math.cos(endAngle), cy + outerR * math.sin(endAngle)),
          radius: Radius.circular(outerR), clockwise: true,
        );
        path.lineTo(cx + innerR * math.cos(endAngle), cy + innerR * math.sin(endAngle));
        path.arcToPoint(
          Offset(cx + innerR * math.cos(startAngle), cy + innerR * math.sin(startAngle)),
          radius: Radius.circular(innerR), clockwise: false,
        );
        path.close();
        canvas.drawPath(path, p);
      }

      final ringPaint = Paint()
        ..color = p.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.06
        ..maskFilter = p.maskFilter;
      canvas.drawCircle(Offset(cx, cy), size.width * 0.47, ringPaint);
    }

    if (glowBlur > 0) drawSymbol(glowPaint);
    drawSymbol(paint);
  }

  @override
  bool shouldRepaint(RadiationPainter old) =>
      old.color != color || old.glowColor != glowColor || old.glowBlur != glowBlur;
}
