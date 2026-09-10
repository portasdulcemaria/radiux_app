import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _prefKey = 'radiux_language_code';

  Locale _locale = const Locale('es');
  Locale get locale => _locale;

  /// Llama esto en main() antes de runApp para restaurar la preferencia guardada.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey) ?? 'es';
    _locale = Locale(code);
    // No notifyListeners aquí — el widget aún no existe.
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }
}
