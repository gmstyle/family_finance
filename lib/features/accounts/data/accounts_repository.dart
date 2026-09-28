import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Account types stored on `families/{id}/accounts/{id}`.
enum AccountType {
  cash,
  bankAccount,
  card,
  wallet;

  static AccountType fromString(String raw) {
    return AccountType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => AccountType.cash,
    );
  }
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalanceMinor,
    required this.openingDate,
    required this.balanceMinor,
    required this.archived,
    required this.createdByUserId,
  });

  final String id;
  final String name;
  final AccountType type;
  final int openingBalanceMinor;
  final String openingDate;
  final int balanceMinor;
  final bool archived;
  final String createdByUserId;

  factory Account.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final opening = (d['openingBalanceMinor'] as num?)?.toInt() ?? 0;
    final balance = (d['balanceMinor'] as num?)?.toInt();
    return Account(
      id: doc.id,
      name: d['name'] as String? ?? '',
      type: AccountType.fromString(d['type'] as String? ?? 'cash'),
      openingBalanceMinor: opening,
      openingDate: d['openingDate'] as String? ?? '',
      // Until the projection trigger runs, fall back to opening balance.
      balanceMinor: balance ?? opening,
      archived: d['archived'] as bool? ?? false,
      createdByUserId: d['createdByUserId'] as String? ?? '',
    );
  }
}

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
