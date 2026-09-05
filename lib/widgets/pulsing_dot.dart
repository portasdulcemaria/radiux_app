import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Indicador neon con pulso suave — úsalo en estados activos, resultados, isotopo seleccionado
///
/// Ejemplo:
/// ```dart
/// PulsingDot(color: AppColors.accent)          // teal neon
/// PulsingDot(color: AppColors.primary, size: 10) // indigo más grande
/// PulsingDot(color: AppColors.success)           // verde OK
/// ```
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final double glowSpread;
  final Duration period;

  const PulsingDot({
    super.key,
    this.color = AppColors.primary,
    this.size = 7,
    this.glowSpread = 6,
    this.period = const Duration(milliseconds: 1800),
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period)
      ..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final s = widget.size;
    final gs = widget.glowSpread;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final glow = _pulse.value; // 0..1
        return Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c,
            boxShadow: [
              // Glow interior — siempre presente
              BoxShadow(
                color: c.withOpacity(0.55 + 0.25 * glow),
                blurRadius: gs * (0.8 + 0.6 * glow),
                spreadRadius: 0,
              ),
              // Aura exterior — pulsa
              BoxShadow(
                color: c.withOpacity(0.18 + 0.18 * glow),
                blurRadius: gs * (2.0 + 1.5 * glow),
                spreadRadius: gs * 0.2 * glow,
              ),
              // Luz blanca especular en el centro
              BoxShadow(
                color: Colors.white.withOpacity(0.22 + 0.12 * glow),
                blurRadius: s * 0.4,
                spreadRadius: -s * 0.1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dot de estado estático — sin animación, para íconos o badges
class StatusDot extends StatelessWidget {
  final Color color;
  final double size;

  const StatusDot({
    super.key,
    this.color = AppColors.success,
    this.size = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.50),
            blurRadius: size * 1.2,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.18),
            blurRadius: size * 0.5,
            spreadRadius: -size * 0.1,
          ),
        ],
      ),
    );
  }
}
