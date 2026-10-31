import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/recurring_rule.dart';
import '../domain/transaction.dart';

/// Firestore CRUD + watch for `families/{id}/recurringRules`.
class RecurringRulesRepository {
  RecurringRulesRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _col(String familyId) => _firestore
      .collection('families')
      .doc(familyId)
      .collection('recurringRules');

  Stream<List<RecurringRule>> watchRules(String familyId) {
    return _col(familyId).snapshots().map((snap) {
      final list = snap.docs.map(RecurringRule.fromDoc).toList()
        ..sort((a, b) {
          final byActive = (b.active ? 1 : 0).compareTo(a.active ? 1 : 0);
          if (byActive != 0) return byActive;
          final byNext = a.nextBookingDate.compareTo(b.nextBookingDate);
          if (byNext != 0) return byNext;
          return a.id.compareTo(b.id);
        });
      return list;
    });
  }

  Future<RecurringRule?> getRule(String familyId, String ruleId) async {
    final doc = await _col(familyId).doc(ruleId).get();
    if (!doc.exists) return null;
    return RecurringRule.fromDoc(doc);
  }

  Future<String> createRule({
    required String familyId,
    required TransactionType type,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    required String currency,
    required int dayOfMonth,
    required String nextBookingDate,
    String? merchant,
    String? note,
    String? endBookingDate,
    bool active = true,
  }) async {
    if (type != TransactionType.expense && type != TransactionType.income) {
      throw ArgumentError('Recurring rules support expense and income only.');
    }
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be > 0');
    }
    if (dayOfMonth < 1 || dayOfMonth > 31) {
      throw ArgumentError.value(dayOfMonth, 'dayOfMonth', 'must be 1–31');
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in required to create a recurring rule.');
    }

    final ref = _col(familyId).doc();
    await ref.set({
      'type': type.name,
      'accountId': accountId,
      'categoryId': categoryId,
      'amountMinor': amountMinor,
      'currency': currency,
      if (merchant != null && merchant.trim().isNotEmpty)
        'merchant': merchant.trim(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      'dayOfMonth': dayOfMonth,
      'active': active,
      'nextBookingDate': nextBookingDate,
      if (endBookingDate != null && endBookingDate.isNotEmpty)
        'endBookingDate': endBookingDate,
      'createdByUserId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateRule({
    required String familyId,
    required String ruleId,
    String? accountId,
    String? categoryId,
    int? amountMinor,
    String? merchant,
    String? note,
    bool? active,
    String? nextBookingDate,
    String? endBookingDate,
    bool clearMerchant = false,
    bool clearNote = false,
    bool clearEndBookingDate = false,
  }) async {
    if (amountMinor != null && amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be > 0');
    }
    final patch = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (accountId != null) patch['accountId'] = accountId;
    if (categoryId != null) patch['categoryId'] = categoryId;
    if (amountMinor != null) patch['amountMinor'] = amountMinor;
    if (active != null) patch['active'] = active;
    if (nextBookingDate != null) patch['nextBookingDate'] = nextBookingDate;
    if (clearEndBookingDate) {
      patch['endBookingDate'] = null;
    } else if (endBookingDate != null) {
      patch['endBookingDate'] = endBookingDate;
    }
    if (clearMerchant) {
      patch['merchant'] = null;
    } else if (merchant != null) {
      patch['merchant'] = merchant.trim().isEmpty ? null : merchant.trim();
    }
    if (clearNote) {
      patch['note'] = null;
    } else if (note != null) {
      patch['note'] = note.trim().isEmpty ? null : note.trim();
    }
    await _col(familyId).doc(ruleId).update(patch);
  }

  Future<void> setActive({
    required String familyId,
    required String ruleId,
    required bool active,
  }) {
    return updateRule(familyId: familyId, ruleId: ruleId, active: active);
  }

  /// Deletes the rule only — past ledger transactions are kept.
  Future<void> deleteRule({required String familyId, required String ruleId}) {
    return _col(familyId).doc(ruleId).delete();
  }
}
