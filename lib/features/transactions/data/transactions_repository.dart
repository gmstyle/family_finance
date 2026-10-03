import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/firebase/functions_client.dart';
import '../domain/transaction.dart';

export 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctionsException;

/// Firestore ledger writes + transfer callables.
class TransactionsRepository {
  TransactionsRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? ffFunctions,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  static const int defaultPageSize = 25;

  CollectionReference<Map<String, dynamic>> _col(String familyId) => _firestore
      .collection('families')
      .doc(familyId)
      .collection('transactions');

  Query<Map<String, dynamic>> _filteredQuery(
    String familyId,
    TransactionFilters filters,
  ) {
    Query<Map<String, dynamic>> q = _col(familyId);

    final accountId = filters.accountId;
    if (accountId != null && accountId.isNotEmpty) {
      q = q.where('accountId', isEqualTo: accountId);
    }
    final categoryId = filters.categoryId;
    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }
    final memberId = filters.memberId;
    if (memberId != null && memberId.isNotEmpty) {
      q = q.where('createdByUserId', isEqualTo: memberId);
    }

    final from = filters.bookingDateFrom;
    final to = filters.bookingDateTo;
    if (from != null && from.isNotEmpty && to != null && to.isNotEmpty) {
      q = q
          .where('bookingDate', isGreaterThanOrEqualTo: from)
          .where('bookingDate', isLessThanOrEqualTo: to);
    } else if (from != null && from.isNotEmpty) {
      q = q.where('bookingDate', isGreaterThanOrEqualTo: from);
    } else if (to != null && to.isNotEmpty) {
      q = q.where('bookingDate', isLessThanOrEqualTo: to);
    }

    return q.orderBy('bookingDate', descending: true);
  }

  TransactionPage _pageFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int pageSize,
  ) {
    final hasMore = docs.length > pageSize;
    final pageDocs = hasMore ? docs.sublist(0, pageSize) : docs;
    return TransactionPage(
      items: pageDocs.map(LedgerTransaction.fromDoc).toList(),
      hasMore: hasMore,
      lastDocument: pageDocs.isEmpty ? null : pageDocs.last,
    );
  }

  /// Real-time first page for [filters] (newest docs within [pageSize]).
  Stream<TransactionPage> watchTransactions({
    required String familyId,
    TransactionFilters filters = const TransactionFilters(),
    int pageSize = defaultPageSize,
  }) {
    return _filteredQuery(familyId, filters)
        .limit(pageSize + 1)
        .snapshots()
        .map((snap) => _pageFromDocs(snap.docs, pageSize));
  }

  /// One-shot page fetch — used for "load more" older pages.
  Future<TransactionPage> fetchTransactions({
    required String familyId,
    TransactionFilters filters = const TransactionFilters(),
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = defaultPageSize,
  }) async {
    var q = _filteredQuery(familyId, filters).limit(pageSize + 1);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    return _pageFromDocs(snap.docs, pageSize);
  }

  Future<LedgerTransaction?> getTransaction(
    String familyId,
    String transactionId,
  ) async {
    final doc = await _col(familyId).doc(transactionId).get();
    if (!doc.exists) return null;
    return LedgerTransaction.fromDoc(doc);
  }

  Future<String> createManualTransaction({
    required String familyId,
    required TransactionType type,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    required String currency,
    required String bookingDate,
    String? merchant,
    String? note,
  }) async {
    if (!type.isManual) {
      throw ArgumentError('Use createTransfer for transfer movements.');
    }
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be > 0');
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in required to create a transaction.');
    }
    final ref = _col(familyId).doc();
    await ref.set({
      'type': type.name,
      'accountId': accountId,
      'categoryId': categoryId,
      'amountMinor': amountMinor,
      'currency': currency,
      'bookingDate': bookingDate,
      if (merchant != null && merchant.trim().isNotEmpty)
        'merchant': merchant.trim(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      'createdByUserId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateManualTransaction({
    required String familyId,
    required String transactionId,
    required TransactionType type,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    required String bookingDate,
    String? merchant,
    String? note,
  }) async {
    if (!type.isManual) {
      throw ArgumentError('Transfer legs are not editable here.');
    }
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be > 0');
    }
    await _col(familyId).doc(transactionId).update({
      'type': type.name,
      'accountId': accountId,
      'categoryId': categoryId,
      'amountMinor': amountMinor,
      'bookingDate': bookingDate,
      'merchant': merchant?.trim().isEmpty ?? true ? null : merchant!.trim(),
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteManualTransaction({
    required String familyId,
    required String transactionId,
  }) {
    return _col(familyId).doc(transactionId).delete();
  }

  Future<void> _ensureAuthForCallable() async {
    final user = _auth.currentUser;
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

  /// Atomic transfer: two transaction legs with the same [transferId].
  Future<String> createTransfer({
    required String sourceAccountId,
    required String destinationAccountId,
    required int amountMinor,
    required String bookingDate,
    String? note,
  }) async {
    final data = await _call<Map<Object?, Object?>>('createTransfer', {
      'sourceAccountId': sourceAccountId,
      'destinationAccountId': destinationAccountId,
      'amountMinor': amountMinor,
      'bookingDate': bookingDate,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return data['transferId']! as String;
  }

  Future<void> deleteTransfer(String transferId) {
    return _call<Map<Object?, Object?>>('deleteTransfer', {
      'transferId': transferId,
    });
  }
}
