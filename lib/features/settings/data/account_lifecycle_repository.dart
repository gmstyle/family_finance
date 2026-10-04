import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/firebase/functions_client.dart';

export 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctionsException;

/// Account deletion + sole-member pre-check (callables / Firestore reads).
class AccountLifecycleRepository {
  AccountLifecycleRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? ffFunctions,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Future<void> _ensureAuthForCallable() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseFunctionsException(
        code: 'unauthenticated',
        message: 'Sign in required before calling Cloud Functions.',
      );
    }
    await user.getIdToken(true);
  }

  Future<T> _call<T>(String name, [Map<String, dynamic>? data]) async {
    await _ensureAuthForCallable();
    debugLogFunctionsCall(name);
    final callable = _functions.httpsCallable(name);
    try {
      final result = await callable.call(data ?? <String, dynamic>{});
      return result.data as T;
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode &&
          (e.code == 'not-found' || e.code == 'NOT_FOUND') &&
          FirebaseBootstrap.shouldUseEmulators) {
        final projectId = Firebase.app().options.projectId;
        debugPrint(
          'ffCallable NOT_FOUND: name=$name project=$projectId '
          'region=$ffFunctionsRegion '
          'host=${FirebaseBootstrap.emulatorHost}:'
          '${FirebaseBootstrap.functionsEmulatorPort}.',
        );
      }
      rethrow;
    }
  }

  /// Whether the current user is the only member of their family (if any).
  Future<bool> isSoleFamilyMember(String? familyId) async {
    if (familyId == null || familyId.isEmpty) return false;
    final snap = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .limit(2)
        .get();
    return snap.docs.length == 1;
  }

  Future<void> deleteAccount({required bool confirmFamilyWipe}) async {
    await _call<Map<Object?, Object?>>('deleteAccount', {
      'confirmFamilyWipe': confirmFamilyWipe,
    });
  }
}
