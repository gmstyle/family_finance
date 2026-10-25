import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes [ThemeMode] (system / light / dark).
class ThemeModeController extends ChangeNotifier {
  ThemeModeController(this._prefs);

  static const _prefsKey = 'ui_theme_mode';

  final SharedPreferences _prefs;

  late ThemeMode _themeMode = _resolveInitial();

  ThemeMode get themeMode => _themeMode;

  static Future<ThemeModeController> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeModeController(prefs);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    await _prefs.setString(_prefsKey, _encode(mode));
    notifyListeners();
  }

  ThemeMode _resolveInitial() {
    final stored = _prefs.getString(_prefsKey);
    if (stored != null) {
      final parsed = _decode(stored);
      if (parsed != null) return parsed;
    }
    return ThemeMode.system;
  }

  static String _encode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  static ThemeMode? _decode(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => null,
  };
}
