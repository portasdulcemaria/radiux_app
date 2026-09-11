import 'dart:math' as math;
import 'unit.dart';

class DecayService {
  /// Fórmula exacta transpilada de JavaScript:
  /// Math.exp(-(Math.log(2) * diffPeriodTime / t2))
  static double decay({
    required double initialActivity,
    required double halfLifeHours,
    required double elapsedHours,
  }) {
    if (halfLifeHours <= 0 || elapsedHours < 0) return initialActivity;

    final double log2 = math.log(2);
    final double logaritmo = math.exp(-(log2 * elapsedHours / halfLifeHours));

    return initialActivity * logaritmo;
  }

  /// Decaimiento directo pasando únicamente la cantidad de vidas medias (n)
  static double decayByHalfLives({
    required double initialActivity,
    required double halfLives,
  }) {
    if (halfLives < 0) return initialActivity;
    return initialActivity * math.exp(-(math.log(2) * halfLives));
  }

  /// A₀ = A(t) / logaritmo — decaimiento inverso exacto
  /// "¿Cuánto necesito AHORA para tener [targetActivity] en [elapsedHours] horas?"
  static double inverseDecay({
    required double targetActivity,
    required double halfLifeHours,
    required double elapsedHours,
  }) {
    if (halfLifeHours <= 0 || elapsedHours <= 0) return targetActivity;

    final double log2 = math.log(2);
    final double logaritmo = math.exp(-(log2 * elapsedHours / halfLifeHours));

    return targetActivity / logaritmo;
  }

  /// Retorna las vidas medias transcurridas (n = t / T½)
  static double halfLivesElapsed({
    required double halfLifeHours,
    required double elapsedHours,
  }) {
    if (halfLifeHours <= 0) return 0.0;
    return elapsedHours / halfLifeHours;
  }

  /// Fracción de actividad remanente usando la constante exponencial
  static double decayFraction({
    required double halfLifeHours,
    required double elapsedHours,
  }) {
    if (halfLifeHours <= 0) return 1.0;
    return math.exp(-(math.log(2) * elapsedHours / halfLifeHours));
  }

  static double percentRemaining({
    required double halfLifeHours,
    required double elapsedHours,
  }) {
    return decayFraction(halfLifeHours: halfLifeHours, elapsedHours: elapsedHours) * 100;
  }

  /// Retorna el porcentaje de reducción (100% - restante)
  static double percentReduction({
    required double halfLifeHours,
    required double elapsedHours,
  }) {
    return 100.0 - percentRemaining(halfLifeHours: halfLifeHours, elapsedHours: elapsedHours);
  }

  static double convert(double value, RadioUnit from, RadioUnit to) {
    if (from.id == to.id) return value;
    final inMBq = value * from.toMBq;
    return inMBq / to.toMBq;
  }

  /// Returns cross-unit label for unified display (e.g. "37.00 mCi" when in MBq)
  static String crossUnit(double valueInUnit, RadioUnit fromUnit) {
    final mbq = valueInUnit * fromUnit.toMBq;
    if (fromUnit.id == 'mci' || fromUnit.id == 'ci' || fromUnit.id == 'uci' || fromUnit.id == 'nci') {
      return '${formatActivity(mbq)} MBq';
    } else {
      final mci = mbq / 37.0;
      return '${formatActivity(mci)} mCi';
    }
  }

  /// Formateador para adaptar decimales sin cortar información relevante
  static String formatActivity(double value, {int maxDecimals = 6}) {
    if (value == 0) return '0';
    final abs = value.abs();

    if (abs >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(2)} × 10⁹';
    } else if (abs >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(2)} × 10⁶';
    } else {
      String formatted = value.toStringAsFixed(maxDecimals);
      if (formatted.contains('.')) {
        formatted = formatted.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      return formatted;
    }
  }
}