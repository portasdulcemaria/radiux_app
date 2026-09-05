class RadioUnit {
  final String id;
  final String label;
  final String fullName;
  final double toMBq; // 1 [unit] = X MBq

  const RadioUnit({
    required this.id,
    required this.label,
    required this.fullName,
    required this.toMBq,
  });
}

final List<RadioUnit> kUnits = [
  RadioUnit(id: 'mbq', label: 'MBq', fullName: 'Megabecquerel', toMBq: 1.0),
  RadioUnit(id: 'gbq', label: 'GBq', fullName: 'Gigabecquerel', toMBq: 1000.0),
  RadioUnit(id: 'kbq', label: 'kBq', fullName: 'Kilobecquerel', toMBq: 0.001),
  RadioUnit(id: 'bq', label: 'Bq', fullName: 'Becquerel', toMBq: 1e-6),
  RadioUnit(id: 'mci', label: 'mCi', fullName: 'Milicurie', toMBq: 37.0),
  RadioUnit(id: 'ci', label: 'Ci', fullName: 'Curie', toMBq: 37000.0),
  RadioUnit(id: 'uci', label: 'µCi', fullName: 'Microcurie', toMBq: 0.037),
  RadioUnit(id: 'nci', label: 'nCi', fullName: 'Nanocurie', toMBq: 37e-9),
  RadioUnit(id: 'dps', label: 'DPS', fullName: 'Desintegraciones/seg', toMBq: 1e-6),
  RadioUnit(id: 'dpm', label: 'DPM', fullName: 'Desintegraciones/min', toMBq: 1.0 / 60000000.0),
];
