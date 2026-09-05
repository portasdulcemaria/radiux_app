import 'dart:convert';

class DecayRecord {
  final String id;
  final DateTime timestamp;
  final String isotopeId;
  final String isotopeSymbol;
  final String isotopeName;
  final double initialActivity;
  final double resultActivity;
  final String unitId;
  final String unitLabel;
  final double elapsedHours;
  final double halfLifeHours;

  const DecayRecord({
    required this.id,
    required this.timestamp,
    required this.isotopeId,
    required this.isotopeSymbol,
    required this.isotopeName,
    required this.initialActivity,
    required this.resultActivity,
    required this.unitId,
    required this.unitLabel,
    required this.elapsedHours,
    required this.halfLifeHours,
  });

  double get fraction => resultActivity / initialActivity;
  double get halfLives => elapsedHours / halfLifeHours;
  double get reductionPct => (1 - fraction) * 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'isotopeId': isotopeId,
        'isotopeSymbol': isotopeSymbol,
        'isotopeName': isotopeName,
        'initialActivity': initialActivity,
        'resultActivity': resultActivity,
        'unitId': unitId,
        'unitLabel': unitLabel,
        'elapsedHours': elapsedHours,
        'halfLifeHours': halfLifeHours,
      };

  factory DecayRecord.fromJson(Map<String, dynamic> j) => DecayRecord(
        id: j['id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        isotopeId: j['isotopeId'] as String,
        isotopeSymbol: j['isotopeSymbol'] as String,
        isotopeName: j['isotopeName'] as String,
        initialActivity: (j['initialActivity'] as num).toDouble(),
        resultActivity: (j['resultActivity'] as num).toDouble(),
        unitId: j['unitId'] as String,
        unitLabel: j['unitLabel'] as String,
        elapsedHours: (j['elapsedHours'] as num).toDouble(),
        halfLifeHours: (j['halfLifeHours'] as num).toDouble(),
      );

  static List<DecayRecord> listFromJson(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => DecayRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<DecayRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());
}
