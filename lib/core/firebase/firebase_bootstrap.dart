import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Keep in sync with `ffFunctionsRegion` / `functions/src/options.ts`.
const String _functionsRegion = 'europe-west1';

/// Firebase bootstrap for real projects and local emulators.
///
/// Flags (compile-time `--dart-define`):
/// - `USE_EMULATORS=true` — connect Auth, Firestore, and Functions to emulators
///   using project id [emulatorProjectId] (default `demo-family-finance`; must
///   match `emulators:start --project …`).
/// - `EMULATOR_ONLY=true` — same as [useEmulators] (alias; implies emulators).
/// - `EMULATOR_PROJECT_ID=…` — override demo project id when emulators are on.
/// - `EMULATOR_USE_FIREBASE_OPTIONS=true` — keep [DefaultFirebaseOptions]
///   project id while using emulators. Start the suite with that same project
///   id or Functions callables will 404 (unknown path).
/// - `EMULATOR_HOST` — override emulator host (Android AVD defaults to
///   `10.0.2.2`; web/desktop to `127.0.0.1`).
///
/// Emulator mode always [FirebaseAuth.signOut]s once after connecting the Auth
/// emulator so cold starts never keep stale refresh tokens.
///
/// When neither emulator flag is set, [DefaultFirebaseOptions] from FlutterFire
/// is used and the app talks to the configured cloud project.
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

  /// Keep real FlutterFire project id while talking to local emulators.
  /// Requires `emulators:start --project <same-as-firebase_options>`.
  static const bool emulatorUseFirebaseOptions = bool.fromEnvironment(
    'EMULATOR_USE_FIREBASE_OPTIONS',
    defaultValue: false,
  );

  static const String _emulatorProjectIdOverride = String.fromEnvironment(
    'EMULATOR_PROJECT_ID',
  );

  /// Project id used for emulator mode (Functions URL path segment).
  static String get emulatorProjectId => _emulatorProjectIdOverride.isNotEmpty
      ? _emulatorProjectIdOverride
      : 'demo-family-finance';

  /// Optional override via `--dart-define=EMULATOR_HOST=...`.
  /// When unset: Android → `10.0.2.2` (AVD loopback to host); else `127.0.0.1`.
  static const String _emulatorHostOverride = String.fromEnvironment(
    'EMULATOR_HOST',
  );

  static String get emulatorHost {
    if (_emulatorHostOverride.isNotEmpty) {
      return _emulatorHostOverride;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

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
    // Functions emulator routes by project id in the URL path. Default local
    // workflow uses demo-family-finance; pairing USE_EMULATORS with the real
    // FlutterFire project id causes "unknown request" / not-found on callables.
    final options = shouldUseEmulators && !emulatorUseFirebaseOptions
        ? _demoOptionsFor(emulatorProjectId)
        : DefaultFirebaseOptions.currentPlatform;

    await _initializeApp(options);

    if (shouldUseEmulators) {
      await _connectEmulators();
      if (kDebugMode) {
        final actual = Firebase.app().options.projectId;
        debugPrint(
          'Firebase emulators: host=$emulatorHost '
          'auth=$authEmulatorPort firestore=$firestoreEmulatorPort '
          'functions=$functionsEmulatorPort '
          'region=$_functionsRegion '
          'projectRequested=${options.projectId} '
          'projectActual=$actual '
          'useEmulators=$useEmulators emulatorOnly=$emulatorOnly '
          'useFirebaseOptions=$emulatorUseFirebaseOptions',
        );
        if (actual != options.projectId) {
          debugPrint(
            'ERROR: Firebase projectId mismatch after init '
            '(requested=${options.projectId}, actual=$actual). '
            'Callables will 404 against the Functions emulator.',
          );
        }
        if (emulatorUseFirebaseOptions &&
            !options.projectId.startsWith('demo-')) {
          debugPrint(
            'WARNING: Emulators + project=${options.projectId}. '
            'Start emulators with --project ${options.projectId} '
            '(Functions 404 if the suite uses a different project id).',
          );
        }
      }
    }
  }

  /// Initialize (or replace) the default Firebase app so [options] win.
  ///
  /// On Android, `google-services.json` can auto-init via
  /// `FirebaseInitProvider` before Dart runs. If that happened with a different
  /// project id, delete and re-create so Functions URLs match the emulator.
  static Future<void> _initializeApp(FirebaseOptions options) async {
    if (Firebase.apps.isNotEmpty) {
      final existing = Firebase.app();
      if (existing.options.projectId == options.projectId) {
        return;
      }
      await existing.delete();
    }

    await Firebase.initializeApp(options: options);

    final actual = Firebase.app().options.projectId;
    if (actual != options.projectId) {
      await Firebase.app().delete();
      await Firebase.initializeApp(options: options);
    }
  }

  static Future<void> _connectEmulators() async {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, authEmulatorPort);
    // Emulator mode always starts signed out. Persisted tokens from a real
    // project or a prior emulator session are invalid against the Auth
    // emulator (e.g. "invalid refresh token") and must not stick across runs.
    await FirebaseAuth.instance.signOut();
    FirebaseFirestore.instance.useFirestoreEmulator(
      emulatorHost,
      firestoreEmulatorPort,
    );
    // Default instance + region-pinned instance (callables use europe-west1).
    FirebaseFunctions.instance.useFunctionsEmulator(
      emulatorHost,
      functionsEmulatorPort,
    );
    FirebaseFunctions.instanceFor(region: _functionsRegion)
        .useFunctionsEmulator(emulatorHost, functionsEmulatorPort);
  }

  /// Emulator options: real FlutterFire credentials + demo [projectId].
  ///
  /// Auth rejects placeholder apiKeys; keep apiKey/appId/messagingSenderId/
  /// storageBucket from [DefaultFirebaseOptions] and only override projectId
  /// (and authDomain) so Functions URLs still match
  /// `emulators:start --project demo-family-finance`.
  static FirebaseOptions _demoOptionsFor(String projectId) {
    final real = DefaultFirebaseOptions.currentPlatform;
    return FirebaseOptions(
      apiKey: real.apiKey,
      appId: real.appId,
      messagingSenderId: real.messagingSenderId,
      projectId: projectId,
      authDomain: '$projectId.firebaseapp.com',
      storageBucket: real.storageBucket,
    );
  }
}
