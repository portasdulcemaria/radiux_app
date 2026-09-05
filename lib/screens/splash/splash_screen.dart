import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_motion.dart';
import '../../widgets/radiation_icon.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Órbitas de los electrones
  late final AnimationController _orbitCtrl;
  // Blobs de fondo flotando
  late final AnimationController _blobCtrl;
  // Glow pulsante del ícono
  late final AnimationController _glowCtrl;
  // Estado del reveal
  bool _showContent = false;
  bool _showProcessing = false;
  bool _showUnlocked = false;
  bool _showCta = false;

  @override
  void initState() {
    super.initState();

    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _blobCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat(reverse: true);

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);

    Future.delayed(400.ms,  () { if (mounted) setState(() => _showContent = true); }); // kept for compat
    Future.delayed(900.ms,  () { if (mounted) setState(() => _showProcessing = true); });
    Future.delayed(2000.ms, () { if (mounted) setState(() => _showUnlocked = true); });
    Future.delayed(2700.ms, () { if (mounted) setState(() => _showCta = true); });
    Future.delayed(5000.ms, () {
      if (mounted && Navigator.canPop(context) == false) {
        HapticFeedback.lightImpact();
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _blobCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bg, // dark navy premium
      body: Stack(
        children: [
          // ── Blobs de fondo animados ───────────────────────────────────
          AnimatedBuilder(
            animation: _blobCtrl,
            builder: (_, __) {
              final t = _blobCtrl.value;
              return Stack(
                children: [
                  _Blob(
                    color: AppColors.primary.withOpacity(0.18),
                    size: size.width * 0.9,
                    offset: Offset(
                      -size.width * 0.2 + t * size.width * 0.15,
                      -size.height * 0.15 + t * size.height * 0.08,
                    ),
                  ),
                  _Blob(
                    color: AppColors.accent.withOpacity(0.12),
                    size: size.width * 0.7,
                    offset: Offset(
                      size.width * 0.4 - t * size.width * 0.1,
                      size.height * 0.55 + t * size.height * 0.06,
                    ),
                  ),
                  _Blob(
                    color: AppColors.primary.withOpacity(0.10),
                    size: size.width * 0.6,
                    offset: Offset(
                      size.width * 0.1 + t * size.width * 0.12,
                      size.height * 0.3 - t * size.height * 0.05,
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Partículas flotantes ──────────────────────────────────────
          ...List.generate(6, (i) => _FloatingParticle(index: i, ctrl: _orbitCtrl)),

          // ── Contenido principal ───────────────────────────────────────
          SafeArea(
            child: Stack(
              children: [
                // Centro fijo: ícono + wordmark — NUNCA se mueven
                Positioned.fill(
                  bottom: 80, // empuja el centro hacia arriba
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ícono
                      _AppIconMicro(glowCtrl: _glowCtrl)
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1, 1),
                            curve: Curves.elasticOut,
                            duration: 800.ms,
                          ),

                      const SizedBox(height: 28),

                      // Wordmark
                      const Text(
                        'Radiux',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                      const SizedBox(height: 8),

                      Text(
                        'MEDICINA NUCLEAR',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.70),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                    ],
                  ),
                ),

                // Abajo: badge + CTA — posición absoluta, no afecta el centro
                Positioned(
                  left: 0, right: 0, bottom: 32,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showProcessing)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: AnimatedSwitcher(
                            duration: AppMotion.enter,
                            child: _showUnlocked
                                ? _UnlockedBadge(key: const ValueKey('unlocked'))
                                : _ProcessingBadge(key: const ValueKey('processing')),
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 20),

                      if (_showCta)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _SplashCTA(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pushReplacementNamed(context, '/home');
                            },
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                      const SizedBox(height: 12),

                      if (_showCta)
                        Text(
                          'v2.0 · Uso clínico supervisado',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.50),
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo con ☢ rotando + órbitas de electrones ──────────────────────────────

class _AnimatedLogo extends StatelessWidget {
  final AnimationController rotCtrl;
  final AnimationController pulseCtrl;
  final AnimationController orbitCtrl;

  const _AnimatedLogo({
    required this.rotCtrl,
    required this.pulseCtrl,
    required this.orbitCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([rotCtrl, pulseCtrl, orbitCtrl]),
      builder: (_, __) {
        final pulse = pulseCtrl.value; // 0..1

        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow outer
              Container(
                width: 160 + pulse * 20,
                height: 160 + pulse * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12 + pulse * 0.10),
                      blurRadius: 60 + pulse * 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),

              // Anillo exterior girando
              Transform.rotate(
                angle: rotCtrl.value * 2 * math.pi,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Punto en el anillo exterior
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.8),
                              boxShadow: [
                                BoxShadow(color: AppColors.primary, blurRadius: 6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Anillo medio contra-rotando
              Transform.rotate(
                angle: -rotCtrl.value * 2 * math.pi * 1.5,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.20),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent.withOpacity(0.9),
                              boxShadow: [
                                BoxShadow(color: AppColors.accent, blurRadius: 5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Círculo central con gradiente
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.9),
                      AppColors.primaryDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4 + pulse * 0.2),
                      blurRadius: 20 + pulse * 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                // El ☢ NO rota — es el marco el que gira, el símbolo queda estático
                child: const Text(
                  '☢',
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Partículas flotantes de fondo ─────────────────────────────────────────

class _FloatingParticle extends StatelessWidget {
  final int index;
  final AnimationController ctrl;

  const _FloatingParticle({required this.index, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rand = math.Random(index * 7 + 13);
    final baseX = rand.nextDouble() * size.width;
    final baseY = rand.nextDouble() * size.height;
    final radius = 2.0 + rand.nextDouble() * 3;
    final speed = 0.3 + rand.nextDouble() * 0.7;
    final phase = rand.nextDouble() * 2 * math.pi;

    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value * speed + phase;
        final dx = math.sin(t * 2 * math.pi) * 20;
        final dy = math.cos(t * 2 * math.pi * 0.7) * 15;
        final opacity = 0.2 + math.sin(t * math.pi).abs() * 0.3;

        return Positioned(
          left: baseX + dx,
          top: baseY + dy,
          child: Container(
            width: radius,
            height: radius,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (index % 2 == 0 ? AppColors.primary : AppColors.accent)
                  .withOpacity(opacity),
            ),
          ),
        );
      },
    );
  }
}

// ── Blob de fondo ─────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final Offset offset;

  const _Blob({required this.color, required this.size, required this.offset});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ── Processing / Unlock badges ────────────────────────────────────────────

class _ProcessingBadge extends StatefulWidget {
  const _ProcessingBadge({super.key});
  @override
  State<_ProcessingBadge> createState() => _ProcessingBadgeState();
}

class _ProcessingBadgeState extends State<_ProcessingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.dramatic)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              children: List.generate(3, (i) {
                final delay = i / 3;
                final t = (_ctrl.value + delay) % 1.0;
                final opacity = math.sin(t * math.pi).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.3 + opacity * 0.7),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Verificando protocolo clínico',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockedBadge extends StatelessWidget {
  const _UnlockedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primaryLight.withOpacity(0.10),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withOpacity(0.2),
            ),
            child: const Icon(Icons.check_rounded, size: 12, color: AppColors.primaryLight),
          ),
          const SizedBox(width: 10),
          Text(
            'Sistema autorizado',
            style: TextStyle(
              color: const Color(0xFF38BDF8).withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String sub;

  const _StatPill({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ícono app interactivo: rota + juego de luces al tocar/arrastrar ──────

class _AppIconMicro extends StatefulWidget {
  final AnimationController glowCtrl;
  const _AppIconMicro({required this.glowCtrl});

  @override
  State<_AppIconMicro> createState() => _AppIconMicroState();
}

class _AppIconMicroState extends State<_AppIconMicro> with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _touchCtrl;

  // Posición del toque relativa al centro del ícono (−1..1)
  Offset _lightPos = Offset.zero;
  bool _isTouched = false;

  @override
  void initState() {
    super.initState();
    // Rotación lenta continua
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    // Burst de luz al tocar
    _touchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _touchCtrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d, Size iconSize) {
    final center = Offset(iconSize.width / 2, iconSize.height / 2);
    final local = d.localPosition - center;
    setState(() {
      _lightPos = Offset(
        (local.dx / (iconSize.width / 2)).clamp(-1.0, 1.0),
        (local.dy / (iconSize.height / 2)).clamp(-1.0, 1.0),
      );
      _isTouched = true;
    });
    // Acelerar rotación al arrastrar
    _spinCtrl.animateTo(
      (_spinCtrl.value + 0.015).clamp(0.0, 1.0) % 1.0,
      duration: Duration.zero,
    );
  }

  void _onPanEnd(_) {
    setState(() => _isTouched = false);
    _touchCtrl.forward(from: 0).then((_) => _touchCtrl.reverse());
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    _touchCtrl.forward(from: 0).then((_) => _touchCtrl.reverse());
  }

  @override
  Widget build(BuildContext context) {
    const iconSize = Size(92, 92);

    return GestureDetector(
      onTapDown: _onTapDown,
      onPanUpdate: (d) => _onPanUpdate(d, iconSize),
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.glowCtrl, _spinCtrl, _touchCtrl]),
        builder: (_, __) {
          final pulse = Curves.easeInOut.transform(widget.glowCtrl.value);
          final touch = Curves.easeOut.transform(_touchCtrl.value);
          final spin = _spinCtrl.value * 2 * math.pi;

          return SizedBox(
            width: iconSize.width,
            height: iconSize.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow pulsante detrás del símbolo
                Container(
                  width: 80 + pulse * 16 + touch * 30,
                  height: 80 + pulse * 16 + touch * 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.22 + pulse * 0.20 + touch * 0.35),
                        blurRadius: 36 + pulse * 20 + touch * 50,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withOpacity(0.10 + touch * 0.20),
                        blurRadius: 60 + touch * 40,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),

                // Burst de luz al tap
                if (touch > 0)
                  Opacity(
                    opacity: touch * (1 - touch) * 4 * 0.6,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                // ☢ rotando — sin fondo, solo el símbolo
                Transform.rotate(
                  angle: spin,
                  child: CustomPaint(
                    size: const Size(72, 72),
                    painter: RadiationPainter(
                      color: Colors.white.withOpacity(0.88 + pulse * 0.12 + touch * 0.12),
                      glowColor: AppColors.primary.withOpacity(0.5 + touch * 0.5),
                      glowBlur: 8 + pulse * 6 + touch * 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RadiationPainter extends CustomPainter {
  final Color color;
  final Color glowColor;
  final double glowBlur;

  const _RadiationPainter({
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

    // Capa glow primero, luego símbolo nítido encima
    if (glowBlur > 0) drawSymbol(glowPaint);
    drawSymbol(paint);
  }

  @override
  bool shouldRepaint(RadiationPainter old) =>
      old.color != color || old.glowColor != glowColor || old.glowBlur != glowBlur;
}

// ── CTA ───────────────────────────────────────────────────────────────────

class _SplashCTA extends StatefulWidget {
  final VoidCallback onTap;
  const _SplashCTA({required this.onTap});

  @override
  State<_SplashCTA> createState() => _SplashCTAState();
}

class _SplashCTAState extends State<_SplashCTA> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, __) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment(-1 + _shimmer.value * 2, 0),
                end: Alignment(1 + _shimmer.value * 2, 0),
                colors: const [
                  AppColors.primaryDark,
                  AppColors.primary,
                  Color(0xFF38BDF8), // sky-400
                  AppColors.primary,
                ],
                stops: const [0.0, 0.35, 0.65, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'Ingresar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          );
        },
      ),
    );
  }
}
