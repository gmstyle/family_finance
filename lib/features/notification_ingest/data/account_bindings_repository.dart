import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/account_binding.dart';

/// Firestore access for `families/{id}/accountBindings/{bindingId}`.
class AccountBindingsRepository {
  AccountBindingsRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _col(String familyId) => _firestore
      .collection('families')
      .doc(familyId)
      .collection('accountBindings');

  /// Stable document id from a package name.
  static String bindingIdFor(String packageName) {
    final raw = packageName.trim().toLowerCase();
    if (raw.isEmpty) return '';
    final collapsed = raw.replaceAll(RegExp(r'[^a-z0-9._]+'), '_');
    final trimmed = collapsed.replaceAll(RegExp(r'^_+|_+$'), '');
    if (trimmed.isEmpty) return '';
    return trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed;
  }

  Stream<List<AccountBinding>> watchBindings(String familyId) {
    return _col(familyId).snapshots().map((snap) {
      final list = snap.docs.map(AccountBinding.fromDoc).toList()
        ..sort((a, b) => a.packageName.compareTo(b.packageName));
      return list;
    });
  }

  Future<AccountBinding?> getBindingForPackage(
    String familyId,
    String packageName,
  ) async {
    final id = bindingIdFor(packageName);
    if (id.isEmpty) return null;
    final doc = await _col(familyId).doc(id).get();
    if (!doc.exists) return null;
    final binding = AccountBinding.fromDoc(doc);
    if (binding.accountId.isEmpty) return null;
    return binding;
  }

  Future<void> setBinding({
    required String familyId,
    required String packageName,
    required String accountId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in required to save account bindings.');
    }
    final id = bindingIdFor(packageName);
    if (id.isEmpty) {
      throw ArgumentError.value(packageName, 'packageName', 'invalid');
    }
    if (accountId.trim().isEmpty) {
      throw ArgumentError.value(accountId, 'accountId', 'required');
    }
    await _col(familyId).doc(id).set({
      'packageName': packageName.trim(),
      'accountId': accountId.trim(),
      'updatedByUserId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearBinding({
    required String familyId,
    required String packageName,
  }) async {
    final id = bindingIdFor(packageName);
    if (id.isEmpty) return;
    await _col(familyId).doc(id).delete();
  }
}
