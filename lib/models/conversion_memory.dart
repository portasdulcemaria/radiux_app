import 'unit.dart';

class ConversionMemory {
  static double? value;
  static RadioUnit? unit;

  static bool hasValue() {
    return value != null && unit != null;
  }

  static void save({
    required double value,
    required RadioUnit unit,
  }) {
    ConversionMemory.value = value;
    ConversionMemory.unit = unit;
  }

  static void clear() {
    value = null;
    unit = null;
  }
}