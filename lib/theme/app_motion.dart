import 'package:flutter/animation.dart';

/// Sistema de física de movimiento unificado — Radiux
/// Un solo set de duraciones y curvas para toda la app.
abstract class AppMotion {
  // ── Duraciones ────────────────────────────────────────────────────────────
  /// Micro-feedback: press, toggle, ripple
  static const quick = Duration(milliseconds: 150);

  /// Cambios de estado: chips, switches, íconos
  static const standard = Duration(milliseconds: 250);

  /// Elementos entrando a pantalla: cards, sheets, modals
  static const enter = Duration(milliseconds: 350);

  /// Elementos saliendo de pantalla
  static const exit = Duration(milliseconds: 200);

  /// Momentos dramáticos: ring, counter, resultado
  static const dramatic = Duration(milliseconds: 900);

  // ── Curvas ────────────────────────────────────────────────────────────────
  /// Salida rápida — para todo lo que entra
  static const curveEnter = Curves.easeOutCubic;

  /// Salida simple — para micro-feedback
  static const curveQuick = Curves.easeOut;

  /// Entrada simple — para lo que sale
  static const curveExit = Curves.easeIn;

  /// Elástica suave — para momentos de énfasis
  static const curveElastic = Curves.elasticOut;

  /// Para el ring y el counter
  static const curveDramatic = Curves.easeOutCubic;
}
