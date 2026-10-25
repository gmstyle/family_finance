import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes [ThemeMode] (system / light / dark).
class ThemeModeController extends ChangeNotifier {
  ThemeModeController._(this._prefs, this._themeMode);

  static const prefsKey = 'ui_theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static Future<ThemeModeController> create() async {
    final prefs = await SharedPreferences.getInstance();
    // Pull latest disk/localStorage values (important on web after a prior write).
    await prefs.reload();
    final stored = prefs.getString(prefsKey);
    final mode = _decode(stored) ?? ThemeMode.system;
    return ThemeModeController._(prefs, mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final ok = await _prefs.setString(prefsKey, _encode(mode));
    if (!ok) {
      // Retry once — some web backends report false on the first write.
      await _prefs.setString(prefsKey, _encode(mode));
    }
  }

  static String _encode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  static ThemeMode? _decode(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => null,
  };
}
