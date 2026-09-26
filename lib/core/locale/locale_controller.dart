import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the app UI locale (`en` / `it`).
///
/// On first launch, uses the system locale when it is English or Italian;
/// otherwise defaults to English.
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs);

  static const supportedLocales = <Locale>[Locale('en'), Locale('it')];

  static const _prefsKey = 'ui_locale';

  final SharedPreferences _prefs;

  late Locale _locale = _resolveInitialLocale();

  Locale get locale => _locale;

  static Future<LocaleController> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocaleController(prefs);
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = _normalize(locale);
    if (normalized == null || normalized == _locale) return;
    _locale = normalized;
    await _prefs.setString(_prefsKey, normalized.languageCode);
    notifyListeners();
  }

  Locale _resolveInitialLocale() {
    final stored = _prefs.getString(_prefsKey);
    if (stored != null) {
      final fromPrefs = _normalize(Locale(stored));
      if (fromPrefs != null) return fromPrefs;
    }

    final system = WidgetsBinding.instance.platformDispatcher.locale;
    return _normalize(system) ?? const Locale('en');
  }

  static Locale? _normalize(Locale locale) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }
    return null;
  }
}
