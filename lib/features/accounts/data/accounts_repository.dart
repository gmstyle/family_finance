import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/account.dart';

/// Firestore CRUD for family accounts (archive only — no hard delete).
class AccountsRepository {
  AccountsRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _col(String familyId) =>
      _firestore.collection('families').doc(familyId).collection('accounts');

  Stream<List<Account>> watchAccounts(
    String familyId, {
    bool includeArchived = false,
  }) {
    return _col(familyId).orderBy('name').snapshots().map((snap) {
      final list = snap.docs.map(Account.fromDoc).toList();
      if (includeArchived) return list;
      return list.where((a) => !a.archived).toList();
    });
  }

  Future<Account?> getAccount(String familyId, String accountId) async {
    final doc = await _col(familyId).doc(accountId).get();
    if (!doc.exists) return null;
    return Account.fromDoc(doc);
  }

  Future<String> createAccount({
    required String familyId,
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
    required String openingDate,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in required to create an account.');
    }
    final ref = _col(familyId).doc();
    await ref.set({
      'name': name.trim(),
      'type': type.name,
      'openingBalanceMinor': openingBalanceMinor,
      'openingDate': openingDate,
      'archived': false,
      'createdByUserId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateAccount({
    required String familyId,
    required String accountId,
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
    required String openingDate,
  }) {
    return _col(familyId).doc(accountId).update({
      'name': name.trim(),
      'type': type.name,
      'openingBalanceMinor': openingBalanceMinor,
      'openingDate': openingDate,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> archiveAccount({
    required String familyId,
    required String accountId,
    bool archived = true,
  }) {
    return _col(familyId).doc(accountId).update({
      'archived': archived,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
