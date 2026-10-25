import 'package:family_finance/core/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ThemeModeController persists across create()', () async {
    SharedPreferences.setMockInitialValues({});
    final a = await ThemeModeController.create();
    expect(a.themeMode, ThemeMode.system);

    await a.setThemeMode(ThemeMode.dark);
    expect(a.themeMode, ThemeMode.dark);

    // Same prefs singleton after a write — mimics app restart with disk data.
    final b = await ThemeModeController.create();
    expect(b.themeMode, ThemeMode.dark);

    await b.setThemeMode(ThemeMode.light);
    final c = await ThemeModeController.create();
    expect(c.themeMode, ThemeMode.light);
  });
}
