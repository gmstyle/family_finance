import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Firebase bootstrap for real projects and local emulators.
///
/// Flags (compile-time `--dart-define`):
/// - `USE_EMULATORS=true` — connect Auth, Firestore, and Functions to emulators.
/// - `EMULATOR_ONLY=true` — use the `demo-family-finance` project id (no real
///   credentials needed). Implies emulators.
///
/// When neither flag is set, [DefaultFirebaseOptions] from FlutterFire is used
/// and the app talks to the configured cloud project.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static const bool useEmulators = bool.fromEnvironment(
    'USE_EMULATORS',
    defaultValue: false,
  );

  static const bool emulatorOnly = bool.fromEnvironment(
    'EMULATOR_ONLY',
    defaultValue: false,
  );

  static const String emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  static const int authEmulatorPort = int.fromEnvironment(
    'AUTH_EMULATOR_PORT',
    defaultValue: 9099,
  );

  static const int firestoreEmulatorPort = int.fromEnvironment(
    'FIRESTORE_EMULATOR_PORT',
    defaultValue: 8080,
  );

  static const int functionsEmulatorPort = int.fromEnvironment(
    'FUNCTIONS_EMULATOR_PORT',
    defaultValue: 5001,
  );

  /// Whether emulators should be wired for this run.
  static bool get shouldUseEmulators => useEmulators || emulatorOnly;

  static Future<void> initialize() async {
    final options = emulatorOnly
        ? _demoOptions
        : DefaultFirebaseOptions.currentPlatform;

    await Firebase.initializeApp(options: options);

    if (shouldUseEmulators) {
      await _connectEmulators();
      if (kDebugMode) {
        debugPrint(
          'Firebase emulators: host=$emulatorHost '
          'auth=$authEmulatorPort firestore=$firestoreEmulatorPort '
          'functions=$functionsEmulatorPort '
          'project=${options.projectId}',
        );
      }
    }
  }

  static Future<void> _connectEmulators() async {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, authEmulatorPort);
    FirebaseFirestore.instance.useFirestoreEmulator(
      emulatorHost,
      firestoreEmulatorPort,
    );
    FirebaseFunctions.instance.useFunctionsEmulator(
      emulatorHost,
      functionsEmulatorPort,
    );
  }

  /// Hand-written options for emulator-only / `demo-*` project mode.
  static FirebaseOptions get _demoOptions {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'demo-api-key',
        appId: '1:1234567890:web:demo',
        messagingSenderId: '1234567890',
        projectId: 'demo-family-finance',
        authDomain: 'demo-family-finance.firebaseapp.com',
        storageBucket: 'demo-family-finance.appspot.com',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'demo-api-key',
          appId: '1:1234567890:android:demo',
          messagingSenderId: '1234567890',
          projectId: 'demo-family-finance',
          storageBucket: 'demo-family-finance.appspot.com',
        );
      case TargetPlatform.windows:
        return const FirebaseOptions(
          apiKey: 'demo-api-key',
          appId: '1:1234567890:web:demo-windows',
          messagingSenderId: '1234567890',
          projectId: 'demo-family-finance',
          authDomain: 'demo-family-finance.firebaseapp.com',
          storageBucket: 'demo-family-finance.appspot.com',
        );
      default:
        return const FirebaseOptions(
          apiKey: 'demo-api-key',
          appId: '1:1234567890:web:demo',
          messagingSenderId: '1234567890',
          projectId: 'demo-family-finance',
          authDomain: 'demo-family-finance.firebaseapp.com',
          storageBucket: 'demo-family-finance.appspot.com',
        );
    }
  }
}
