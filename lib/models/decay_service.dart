import 'dart:math' as math;
import 'unit.dart';

class DecayService {
  /// A(t) = A₀ × 2^(−t/T½)
  static double decay({
    required double initialActivity,
    required double halfLifeHours,
    required double elapsedHours,
  }) {
    if (halfLifeHours <= 0) return initialActivity;
    if (elapsedHours < 0) return initialActivity;
    return initialActivity * math.pow(2, -elapsedHours / halfLifeHours);
  }

  /// A₀ = A(t) × 2^(t/T½)  — inverse decay
  /// "¿Cuánto necesito AHORA para tener [targetActivity] en [elapsedHours] horas?"
  static double inverseDecay({
    required double targetActivity,
    required double halfLifeHours,
    required double elapsedHours,
  }) {
    if (halfLifeHours <= 0) return targetActivity;
    if (elapsedHours <= 0) return targetActivity;
    return targetActivity * math.pow(2, elapsedHours / halfLifeHours);
  }

  static double decayFraction({
    required double halfLifeHours,
    required double elapsedHours,
  }) {
    return math.pow(2, -elapsedHours / halfLifeHours).toDouble();
  }

  static double percentRemaining({
    required double halfLifeHours,
    required double elapsedHours,
  }) {
    return decayFraction(halfLifeHours: halfLifeHours, elapsedHours: elapsedHours) * 100;
  }

  static double convert(double value, RadioUnit from, RadioUnit to) {
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

  /// Smart format: avoid too many or too few decimals
  static String formatActivity(double value) {
    if (value == 0) return '0';
    final abs = value.abs();
    if (abs >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(2)} × 10⁹';
    } else if (abs >= 1e6) {
      return (value / 1e6).toStringAsFixed(2) + ' × 10⁶';
    } else if (abs >= 10000) {
      return value.toStringAsFixed(2);
    } else if (abs >= 100) {
      return value.toStringAsFixed(2);
    } else if (abs >= 1) {
      return value.toStringAsFixed(3);
    } else if (abs >= 0.001) {
      return value.toStringAsFixed(3);
    } else {
      return value.toStringAsExponential(4);
    }
  }
}
