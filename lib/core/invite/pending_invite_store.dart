import 'package:shared_preferences/shared_preferences.dart';

/// Survives full page reload (web) after email verification opens a new tab.
abstract final class PendingInviteStore {
  static const _keyToken = 'pending_invite_token';

  static Future<void> saveToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, trimmed);
  }

  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }
}
