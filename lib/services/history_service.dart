import 'package:shared_preferences/shared_preferences.dart';
import '../models/decay_record.dart';

class HistoryService {
  HistoryService._();
  static final HistoryService instance = HistoryService._();

  static const _key = 'decay_history_v1';
  static const _maxRecords = 200;

  List<DecayRecord> _cache = [];
  bool _loaded = false;

  Future<List<DecayRecord>> load() async {
    if (_loaded) return List.unmodifiable(_cache);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        _cache = DecayRecord.listFromJson(raw);
        _cache.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } catch (_) {
        _cache = [];
      }
    }
    // Auto-clean: keep only last 30 days
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _cache = _cache.where((r) => r.timestamp.isAfter(cutoff)).toList();
    _loaded = true;
    return List.unmodifiable(_cache);
  }

  Future<void> save(DecayRecord record) async {
    await load(); // ensure loaded
    _cache.insert(0, record);
    if (_cache.length > _maxRecords) {
      _cache = _cache.sublist(0, _maxRecords);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, DecayRecord.listToJson(_cache));
  }

  Future<void> delete(String id) async {
    await load();
    _cache.removeWhere((r) => r.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, DecayRecord.listToJson(_cache));
  }

  Future<void> clearAll() async {
    _cache = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
