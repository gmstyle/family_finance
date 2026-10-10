import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/firebase/functions_client.dart';
import '../../../core/invite/invite_links.dart';
import '../domain/family.dart';

export 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctionsException;

/// Firestore reads + membership callables.
class FamilyRepository {
  FamilyRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? ffFunctions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  /// Ensure Auth has a current user and a fresh ID token (emulator often
  /// reports `auth: MISSING` if the callable races ahead of token minting).
  Future<void> _ensureAuthForCallable() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseFunctionsException(
        code: 'unauthenticated',
        message: 'Sign in required before calling Cloud Functions.',
      );
    }
    await user.getIdToken(/* forceRefresh */ true);
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
          '${FirebaseBootstrap.functionsEmulatorPort}. '
          'Emulator must be started with --project $projectId '
          'and the callable must be registered in $ffFunctionsRegion.',
        );
      }
      rethrow;
    }
  }

  Future<String> createFamily({
    required String name,
    String currency = 'EUR',
    String timezone = 'Europe/Rome',
  }) async {
    final data = await _call<Map<Object?, Object?>>('createFamily', {
      'name': name,
      'currency': currency,
      'timezone': timezone,
    });
    return data['familyId']! as String;
  }

  Future<FamilyInvite> createInvite({required String invitedEmail}) async {
    final data = await _call<Map<Object?, Object?>>('createInvite', {
      'invitedEmail': invitedEmail,
    });
    final token = data['token']! as String;
    final inviteLinkRaw = data['inviteLink'] as String?;
    return FamilyInvite(
      id: data['inviteId']! as String,
      invitedEmail: data['invitedEmail']! as String,
      token: token,
      status: 'pending',
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? ''),
      inviteLink: inviteLinkRaw ?? inviteUrlForToken(token),
      emailQueued: data['emailQueued'] == true,
    );
  }

  Future<void> revokeInvite(String inviteId) =>
      _call<Map<Object?, Object?>>('revokeInvite', {'inviteId': inviteId});

  Future<String> acceptInvite(String token) async {
    try {
      final data = await _call<Map<Object?, Object?>>('acceptInvite', {
        'token': token,
      });
      return data['familyId']! as String;
    } on FirebaseFunctionsException catch (e) {
      final msg = (e.message ?? '').toLowerCase();
      if (e.code == 'failed-precondition' && msg.contains('not pending')) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final snap = await _firestore.collection('users').doc(uid).get(
            const GetOptions(source: Source.server),
          );
          final id = snap.data()?['familyId'] as String?;
          if (id != null && id.isNotEmpty) {
            return id;
          }
        }
      }
      rethrow;
    }
  }

  Future<void> leaveFamily() => _call<Map<Object?, Object?>>('leaveFamily');

  Future<void> removeMember(String userId) =>
      _call<Map<Object?, Object?>>('removeMember', {'userId': userId});

  Future<void> updateMemberRole({
    required String userId,
    required String role,
  }) => _call<Map<Object?, Object?>>('updateMemberRole', {
    'userId': userId,
    'role': role,
  });

  Future<void> transferOwnership(String userId) =>
      _call<Map<Object?, Object?>>('transferOwnership', {'userId': userId});

  Stream<FamilyInfo?> watchFamily(String familyId) {
    return _firestore.collection('families').doc(familyId).snapshots().map((s) {
      final d = s.data();
      if (d == null) return null;
      return FamilyInfo(
        id: s.id,
        name: d['name'] as String? ?? '',
        currency: d['currency'] as String? ?? 'EUR',
        timezone: d['timezone'] as String? ?? 'UTC',
        ownerId: d['ownerId'] as String? ?? '',
        status: d['status'] as String? ?? 'active',
      );
    });
  }

  Stream<List<FamilyMember>> watchMembers(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final d = doc.data();
            return FamilyMember(
              userId: doc.id,
              role: d['role'] as String? ?? 'member',
              displayName: d['displayName'] as String? ?? doc.id,
            );
          }).toList();
        });
  }

  Stream<List<FamilyInvite>> watchPendingInvites(String familyId) {
    return _firestore
        .collection('invites')
        .where('familyId', isEqualTo: familyId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final d = doc.data();
            final expires = d['expiresAt'];
            return FamilyInvite(
              id: doc.id,
              invitedEmail: d['invitedEmail'] as String? ?? '',
              token: d['token'] as String? ?? '',
              status: d['status'] as String? ?? 'pending',
              expiresAt: expires is Timestamp ? expires.toDate() : null,
            );
          }).toList();
        });
  }
}
