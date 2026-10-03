import 'package:cloud_firestore/cloud_firestore.dart';

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
