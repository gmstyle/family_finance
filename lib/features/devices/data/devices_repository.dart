import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registers the FCM device token under `users/{uid}/devices/{deviceId}`.
///
/// Android only — web skips push and relies on in-app budget period alerts.
class DevicesRepository {
  DevicesRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _prefsDeviceIdKey = 'fcm_device_id';

  DocumentReference<Map<String, dynamic>> _deviceRef(
    String uid,
    String deviceId,
  ) => _firestore
      .collection('users')
      .doc(uid)
      .collection('devices')
      .doc(deviceId);

  Future<String> _persistentDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsDeviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id =
        'd_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 30)}';
    await prefs.setString(_prefsDeviceIdKey, id);
    return id;
  }

  Future<void> upsertToken({
    required String token,
    required String platform,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final deviceId = await _persistentDeviceId();
    await _deviceRef(uid, deviceId).set({
      'token': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString(_prefsDeviceIdKey);
    if (deviceId == null || deviceId.isEmpty) return;
    await _deviceRef(uid, deviceId).delete();
  }
}

/// Starts FCM token sync when the user is signed in (Android).
class FcmRegistration {
  FcmRegistration({
    required this.auth,
    DevicesRepository? devices,
    FirebaseMessaging? messaging,
  }) : _devices = devices ?? DevicesRepository(),
       _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseAuth auth;
  final DevicesRepository _devices;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _tokenSub;
  StreamSubscription<User?>? _authSub;
  bool _started = false;

  /// No-op on web / non-Android. Safe to call once from [main].
  void start() {
    if (_started) return;
    _started = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _authSub = auth.authStateChanges().listen((user) {
      if (user == null) {
        _tokenSub?.cancel();
        _tokenSub = null;
        return;
      }
      unawaited(_register());
    });
  }

  Future<void> _register() async {
    try {
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _devices.upsertToken(token: token, platform: 'android');
      }
      await _tokenSub?.cancel();
      _tokenSub = _messaging.onTokenRefresh.listen((token) {
        unawaited(_devices.upsertToken(token: token, platform: 'android'));
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM registration skipped: $e');
      }
    }
  }

  void dispose() {
    _tokenSub?.cancel();
    _authSub?.cancel();
  }
}
