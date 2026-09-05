import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RadiuxAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showMenuButton;

  const RadiuxAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showMenuButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Row(
            children: [
              // Lockup: símbolo + wordmark juntos a la izquierda
              const _RadiuxLockup(),
              const Spacer(),
              // Acciones a la derecha
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Lockup horizontal: ☢ + "Radiux"
class _RadiuxLockup extends StatelessWidget {
  const _RadiuxLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: const Size(24, 24),
          painter: _RadiationMiniPainter(),
        ),
        const SizedBox(width: 8),
        const Text(
          'Radiux',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _RadiationMiniPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;

    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final paint = Paint()
      ..color = const Color(0xFFEEEEFF).withOpacity(0.90)
      ..style = PaintingStyle.fill;

    void drawSymbol(Paint p) {
      canvas.drawCircle(Offset(cx, cy), w * 0.10, p);

      final innerR = w * 0.155;
      final outerR = w * 0.42;
      const sweep = 0.9;

      for (int i = 0; i < 3; i++) {
        final angle = (i * 2 * math.pi / 3) - math.pi / 2;
        final startAngle = angle - sweep / 2;
        final endAngle = angle + sweep / 2;

        final path = Path();
        path.moveTo(cx + innerR * math.cos(startAngle), cy + innerR * math.sin(startAngle));
        path.lineTo(cx + outerR * math.cos(startAngle), cy + outerR * math.sin(startAngle));
        path.arcToPoint(
          Offset(cx + outerR * math.cos(endAngle), cy + outerR * math.sin(endAngle)),
          radius: Radius.circular(outerR),
          clockwise: true,
        );
        path.lineTo(cx + innerR * math.cos(endAngle), cy + innerR * math.sin(endAngle));
        path.arcToPoint(
          Offset(cx + innerR * math.cos(startAngle), cy + innerR * math.sin(startAngle)),
          radius: Radius.circular(innerR),
          clockwise: false,
        );
        path.close();
        canvas.drawPath(path, p);
      }

      final ringPaint = Paint()
        ..color = p.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06;
      canvas.drawCircle(Offset(cx, cy), w * 0.47, ringPaint);
    }

    drawSymbol(glowPaint);
    drawSymbol(paint);
  }

  @override
  bool shouldRepaint(_RadiationMiniPainter old) => false;
}
