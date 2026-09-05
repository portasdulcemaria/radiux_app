import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fondo ambiente — 3 glows con pulso de opacidad perceptible.
/// Ciclo 7s, amplitud suficiente para sentirse sin distraer.
class AnimatedNuclearBackground extends StatefulWidget {
  const AnimatedNuclearBackground({super.key});

  @override
  State<AnimatedNuclearBackground> createState() =>
      _AnimatedNuclearBackgroundState();
}

class _AnimatedNuclearBackgroundState
    extends State<AnimatedNuclearBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _AmbientGlowPainter(_ctrl.value),
          ),
        ),
      ],
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  final double t;
  _AmbientGlowPainter(this.t);

  double _s(double freq, double phase) =>
      math.sin(t * math.pi * 2 * freq + phase);

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // Glow indigo — superior izquierda
    // Pulsa 0.04 → 0.16, ciclo desfasado
    final op1 = (0.10 + 0.06 * _s(1.0, 0.0)).clamp(0.04, 0.16);
    _draw(canvas, Offset(W * 0.10, H * 0.12), W * 0.70,
        AppColors.primary.withOpacity(op1));

    // Glow teal — inferior derecha, desfase 1/3 de ciclo
    final op2 = (0.07 + 0.05 * _s(1.0, 2.1)).clamp(0.02, 0.12);
    _draw(canvas, Offset(W * 0.90, H * 0.78), W * 0.55,
        AppColors.accent.withOpacity(op2));

    // Glow violeta — superior derecha, desfase 2/3 de ciclo
    final op3 = (0.06 + 0.04 * _s(1.0, 4.2)).clamp(0.02, 0.10);
    _draw(canvas, Offset(W * 0.92, H * 0.18), W * 0.38,
        const Color(0xFF7C3AED).withOpacity(op3));
  }

  void _draw(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..blendMode = BlendMode.srcOver,
    );
  }

  @override
  bool shouldRepaint(_AmbientGlowPainter old) => old.t != t;
}
