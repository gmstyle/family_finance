import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/firebase/functions_client.dart';

export 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctionsException;

class FamilyMember {
  const FamilyMember({
    required this.userId,
    required this.role,
    required this.displayName,
  });

  final String userId;
  final String role;
  final String displayName;

  bool get isAdmin => role == 'admin';
}

class FamilyInvite {
  const FamilyInvite({
    required this.id,
    required this.invitedEmail,
    required this.token,
    required this.status,
    this.expiresAt,
  });

  final String id;
  final String invitedEmail;
  final String token;
  final String status;
  final DateTime? expiresAt;
}

class FamilyInfo {
  const FamilyInfo({
    required this.id,
    required this.name,
    required this.currency,
    required this.timezone,
    required this.ownerId,
    required this.status,
  });

  final String id;
  final String name;
  final String currency;
  final String timezone;
  final String ownerId;
  final String status;
}

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
    return FamilyInvite(
      id: data['inviteId']! as String,
      invitedEmail: data['invitedEmail']! as String,
      token: data['token']! as String,
      status: 'pending',
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? ''),
    );
  }

  Future<void> revokeInvite(String inviteId) =>
      _call<Map<Object?, Object?>>('revokeInvite', {'inviteId': inviteId});

  Future<String> acceptInvite(String token) async {
    final data = await _call<Map<Object?, Object?>>('acceptInvite', {
      'token': token,
    });
    return data['familyId']! as String;
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

/// UI-facing family actions wrapping [FamilyRepository].
class FamilyController extends ChangeNotifier {
  FamilyController({FamilyRepository? repository})
    : _repository = repository ?? FamilyRepository();

  final FamilyRepository _repository;

  bool _busy = false;
  String? _errorMessage;
  FamilyInvite? _lastCreatedInvite;

  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  FamilyInvite? get lastCreatedInvite => _lastCreatedInvite;

  FamilyRepository get repository => _repository;

  Future<T> _guard<T>(Future<T> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } on FirebaseFunctionsException catch (e) {
      _errorMessage = _formatFunctionsError(e);
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String> createFamily({
    required String name,
    String currency = 'EUR',
    String timezone = 'Europe/Rome',
  }) {
    return _guard(
      () => _repository.createFamily(
        name: name,
        currency: currency,
        timezone: timezone,
      ),
    );
  }

  Future<FamilyInvite> createInvite(String email) {
    return _guard(() async {
      final invite = await _repository.createInvite(invitedEmail: email);
      _lastCreatedInvite = invite;
      return invite;
    });
  }

  Future<void> revokeInvite(String inviteId) =>
      _guard(() => _repository.revokeInvite(inviteId));

  Future<String> acceptInvite(String token) =>
      _guard(() => _repository.acceptInvite(token));

  Future<void> leaveFamily() => _guard(() => _repository.leaveFamily());

  Future<void> removeMember(String userId) =>
      _guard(() => _repository.removeMember(userId));

  Future<void> updateMemberRole({
    required String userId,
    required String role,
  }) => _guard(() => _repository.updateMemberRole(userId: userId, role: role));

  Future<void> transferOwnership(String userId) =>
      _guard(() => _repository.transferOwnership(userId));

  void clearLastInvite() {
    _lastCreatedInvite = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  static String _formatFunctionsError(FirebaseFunctionsException e) {
    final parts = <String>[e.code];
    if (e.message != null && e.message!.trim().isNotEmpty) {
      parts.add(e.message!.trim());
    }
    final details = e.details;
    if (details != null) {
      parts.add(details.toString());
    }
    if (e.code == 'not-found' || e.code == 'NOT_FOUND') {
      parts.add(
        '(callable missing or wrong project/region — '
        'check emulator --project and Functions region)',
      );
    }
    return parts.join(' — ');
  }
}
