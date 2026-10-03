import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../domain/notification_parse_patterns.dart';

/// Remote Config keys for notification ingest.
abstract final class NotificationRemoteConfigKeys {
  static const packageAllowlist = 'notification_package_allowlist';
  static const parsePatterns = 'notification_parse_patterns';
}

/// Loaded allowlist + parse patterns (with built-in defaults).
class NotificationIngestConfig {
  const NotificationIngestConfig({
    required this.allowedPackages,
    required this.patterns,
  });

  final List<String> allowedPackages;
  final NotificationParsePatterns patterns;

  static const defaultWalletPackage = 'com.google.android.apps.walletnfcrel';

  factory NotificationIngestConfig.defaults() {
    return NotificationIngestConfig(
      allowedPackages: const [defaultWalletPackage],
      patterns: NotificationParsePatterns.defaults(),
    );
  }
}

/// Fetches notification ingest config from Firebase Remote Config.
class NotificationRemoteConfig {
  NotificationRemoteConfig({FirebaseRemoteConfig? remoteConfig})
    : _rc = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _rc;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await _rc.setDefaults({
        NotificationRemoteConfigKeys.packageAllowlist: jsonEncode([
          NotificationIngestConfig.defaultWalletPackage,
        ]),
        NotificationRemoteConfigKeys.parsePatterns: '{}',
      });
      await _rc.fetchAndActivate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Remote Config init skipped: $e');
      }
    }
    _initialized = true;
  }

  /// Loads allowlist + patterns; falls back to defaults on any failure.
  Future<NotificationIngestConfig> load() async {
    await _ensureInitialized();
    try {
      final packages = _parsePackageAllowlist(
        _rc.getString(NotificationRemoteConfigKeys.packageAllowlist),
      );
      final patterns = _parsePatterns(
        _rc.getString(NotificationRemoteConfigKeys.parsePatterns),
      );
      return NotificationIngestConfig(
        allowedPackages: packages,
        patterns: patterns,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Remote Config parse failed, using defaults: $e');
      }
      return NotificationIngestConfig.defaults();
    }
  }

  List<String> _parsePackageAllowlist(String raw) {
    if (raw.trim().isEmpty) {
      return NotificationIngestConfig.defaults().allowedPackages;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return NotificationIngestConfig.defaults().allowedPackages;
    }
    final packages = decoded
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (packages.isEmpty) {
      return NotificationIngestConfig.defaults().allowedPackages;
    }
    return packages;
  }

  NotificationParsePatterns _parsePatterns(String raw) {
    if (raw.trim().isEmpty || raw.trim() == '{}') {
      return NotificationParsePatterns.defaults();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return NotificationParsePatterns.defaults();
    }
    List<String>? asStringList(Object? value) {
      if (value is! List) return null;
      return value.map((e) => e.toString()).toList();
    }

    return NotificationParsePatterns.fromRemoteConfig(
      amountRegexes: asStringList(decoded['amountPatterns']),
      merchantRegexes: asStringList(decoded['merchantPatterns']),
      dateRegexes: asStringList(decoded['datePatterns']),
    );
  }
}
