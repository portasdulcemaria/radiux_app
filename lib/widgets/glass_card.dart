import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';

/// Glassmorphism card — BackdropFilter blur + reflejo de vidrio + respuesta háptica visual
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool hasBorderGlow;
  final Color? glowColor;
  final bool isActive;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.lg,
    this.hasBorderGlow = false,
    this.glowColor,
    this.isActive = false,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? AppColors.primary;
    final br = BorderRadius.circular(widget.borderRadius);

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null ? (_) { setState(() => _pressed = false); widget.onTap?.call(); } : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: AppMotion.quick,
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final borderAlpha = widget.isActive
                ? (55 + 35 * _ctrl.value).toInt()
                : 45;
            final shadowBlur = widget.isActive
                ? 20.0 + 12.0 * _ctrl.value
                : 0.0;
            final shadowAlpha = widget.isActive
                ? (18 + 14 * _ctrl.value).toInt()
                : 0;

            return Container(
              decoration: BoxDecoration(
                borderRadius: br,
                border: Border.all(
                  color: widget.isActive
                      ? glow.withAlpha(borderAlpha)
                      : AppColors.border.withAlpha(60),
                  width: widget.isActive ? 1.2 : 0.8,
                ),
                // Usa AppElevation: raised para cards activas, resting para reposo
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: glow.withAlpha(shadowAlpha),
                          blurRadius: shadowBlur,
                          spreadRadius: -2,
                          offset: const Offset(0, 4),
                        ),
                        ...AppElevation.resting,
                      ]
                    : AppElevation.resting,
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: br,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Stack(
                children: [
                  // ── Fondo glassmorphism ──────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.07),
                          AppColors.surface.withOpacity(0.80),
                          AppColors.surface.withOpacity(0.90),
                        ],
                        stops: const [0.0, 0.40, 1.0],
                      ),
                    ),
                    child: Padding(
                      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.base),
                      child: widget.child,
                    ),
                  ),

                  // ── Reflejo de vidrio — franja superior ─────────────────
                  // Simula luz rebotando en la superficie del vidrio (efecto 3D)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.11),
                              Colors.white.withOpacity(0.04),
                              Colors.white.withOpacity(0),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Brillo especular diagonal — esquina superior izquierda ──
                  // El destello diagonal que da sensación de material real
                  Positioned(
                    top: 0,
                    left: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 120,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topLeft,
                            radius: 1.0,
                            colors: [
                              Colors.white.withOpacity(0.13),
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary button con gradiente
class GradientBorderButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget? icon;

  const GradientBorderButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<GradientBorderButton> createState() => _GradientBorderButtonState();
}

class _GradientBorderButtonState extends State<GradientBorderButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) { setState(() => _pressed = false); widget.onTap?.call(); } : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.quick,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              gradient: enabled
                  ? const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: enabled ? null : AppColors.cardHover,
              boxShadow: enabled
                  ? AppElevation.glow(
                      AppColors.primary,
                      intensity: 0.15 + 0.10 * _pulse.value,
                    )
                  : null,
            ),
            child: child,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
              else if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: enabled ? Colors.white : AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Result card compacta
class ResultCard extends StatelessWidget {
  final String value;
  final String unit;
  final String? label;
  final Color? glowColor;
  final VoidCallback? onCopy;

  const ResultCard({
    super.key,
    required this.value,
    required this.unit,
    this.label,
    this.glowColor,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? AppColors.accent;
    return GlassCard(
      hasBorderGlow: true,
      glowColor: glow,
      isActive: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (label != null) ...[
          Text(label!,
              style: TextStyle(
                  color: glow,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ),
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(unit,
                style: TextStyle(
                    color: glow, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (onCopy != null) ...[
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: onCopy,
            child: Row(children: [
              Icon(Icons.copy_rounded, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text('Copiar resultado',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ]),
          ),
        ],
      ]),
    );
  }
}
