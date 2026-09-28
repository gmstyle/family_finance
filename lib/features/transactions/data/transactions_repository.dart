import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/firebase/functions_client.dart';

export 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctionsException;

/// Ledger transaction types.
enum TransactionType {
  expense,
  income,
  refund,
  transfer;

  static TransactionType fromString(String raw) {
    return TransactionType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => TransactionType.expense,
    );
  }

  bool get isManual =>
      this == TransactionType.expense ||
      this == TransactionType.income ||
      this == TransactionType.refund;
}

enum TransferRole {
  source,
  destination;

  static TransferRole? fromString(String? raw) {
    if (raw == null) return null;
    return TransferRole.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => TransferRole.source,
    );
  }
}

class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.type,
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.bookingDate,
    required this.createdByUserId,
    this.categoryId,
    this.merchant,
    this.note,
    this.transferId,
    this.transferRole,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final TransactionType type;
  final String accountId;
  final String? categoryId;
  final int amountMinor;
  final String currency;
  final String bookingDate;
  final String? merchant;
  final String? note;
  final String? transferId;
  final TransferRole? transferRole;
  final String createdByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LedgerTransaction.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    final created = d['createdAt'];
    final updated = d['updatedAt'];
    return LedgerTransaction(
      id: doc.id,
      type: TransactionType.fromString(d['type'] as String? ?? 'expense'),
      accountId: d['accountId'] as String? ?? '',
      categoryId: d['categoryId'] as String?,
      amountMinor: (d['amountMinor'] as num?)?.toInt() ?? 0,
      currency: d['currency'] as String? ?? 'EUR',
      bookingDate: d['bookingDate'] as String? ?? '',
      merchant: d['merchant'] as String?,
      note: d['note'] as String?,
      transferId: d['transferId'] as String?,
      transferRole: TransferRole.fromString(d['transferRole'] as String?),
      createdByUserId: d['createdByUserId'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }
}

class TransactionFilters {
  const TransactionFilters({
    this.accountId,
    this.categoryId,
    this.memberId,
    this.bookingDateFrom,
    this.bookingDateTo,
  });

  final String? accountId;
  final String? categoryId;
  final String? memberId;
  final String? bookingDateFrom;
  final String? bookingDateTo;

  bool get hasAny =>
      (accountId != null && accountId!.isNotEmpty) ||
      (categoryId != null && categoryId!.isNotEmpty) ||
      (memberId != null && memberId!.isNotEmpty) ||
      (bookingDateFrom != null && bookingDateFrom!.isNotEmpty) ||
      (bookingDateTo != null && bookingDateTo!.isNotEmpty);

  TransactionFilters copyWith({
    String? accountId,
    String? categoryId,
    String? memberId,
    String? bookingDateFrom,
    String? bookingDateTo,
    bool clearAccountId = false,
    bool clearCategoryId = false,
    bool clearMemberId = false,
    bool clearBookingDateFrom = false,
    bool clearBookingDateTo = false,
  }) {
    return TransactionFilters(
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      memberId: clearMemberId ? null : (memberId ?? this.memberId),
      bookingDateFrom: clearBookingDateFrom
          ? null
          : (bookingDateFrom ?? this.bookingDateFrom),
      bookingDateTo: clearBookingDateTo
          ? null
          : (bookingDateTo ?? this.bookingDateTo),
    );
  }
}

class TransactionPage {
  const TransactionPage({
    required this.items,
    required this.hasMore,
    this.lastDocument,
  });

  final List<LedgerTransaction> items;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
}

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
