import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';

/// Must match `FUNCTIONS_REGION` / `callableOpts` in `functions/src/options.ts`.
const String ffFunctionsRegion = 'europe-west1';

/// Cloud Functions client pinned to the deployed region.
FirebaseFunctions get ffFunctions =>
    FirebaseFunctions.instanceFor(region: ffFunctionsRegion);

/// Debug-only context for callable troubleshooting (project / region / host).
void debugLogFunctionsCall(String name) {
  if (!kDebugMode) return;
  final projectId = Firebase.app().options.projectId;
  final host = FirebaseBootstrap.shouldUseEmulators
      ? '${FirebaseBootstrap.emulatorHost}:'
            '${FirebaseBootstrap.functionsEmulatorPort}'
      : 'cloud';
  debugPrint(
    'ffCallable: name=$name project=$projectId '
    'region=$ffFunctionsRegion host=$host',
  );
}
