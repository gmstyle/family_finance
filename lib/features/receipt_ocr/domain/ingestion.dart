import 'package:cloud_firestore/cloud_firestore.dart';

/// Result of creating (or finding) an ingestion draft from a notification.
class NotificationDraftResult {
  const NotificationDraftResult({
    required this.dedupKey,
    required this.created,
    required this.status,
  });

  final String dedupKey;
  final bool created;
  final IngestionStatus status;
}

/// Ingestion draft status (Firestore `status` field).
enum IngestionStatus {
  needsReview,
  possibleDuplicate,
  confirmed,
  discarded;

  static IngestionStatus fromString(String raw) {
    return IngestionStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => IngestionStatus.needsReview,
    );
  }
}

/// How the draft was created.
enum IngestionSource {
  receiptOcr,
  notification;

  static IngestionSource fromString(String raw) {
    return IngestionSource.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => IngestionSource.receiptOcr,
    );
  }
}

class MerchantRule {
  const MerchantRule({
    required this.merchantKey,
    this.categoryId,
    this.accountId,
  });

  final String merchantKey;
  final String? categoryId;
  final String? accountId;

  factory MerchantRule.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return MerchantRule(
      merchantKey: doc.id,
      categoryId: d['categoryId'] as String?,
      accountId: d['accountId'] as String?,
    );
  }
}

class IngestionDraft {
  const IngestionDraft({
    required this.id,
    required this.status,
    required this.source,
    required this.createdByUserId,
    this.amountMinor,
    this.merchant,
    this.bookingDate,
    this.accountId,
    this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final IngestionStatus status;
  final IngestionSource source;
  final String createdByUserId;
  final int? amountMinor;
  final String? merchant;
  final String? bookingDate;
  final String? accountId;
  final String? categoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending =>
      status == IngestionStatus.needsReview ||
      status == IngestionStatus.possibleDuplicate;

  factory IngestionDraft.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final created = d['createdAt'];
    final updated = d['updatedAt'];
    return IngestionDraft(
      id: doc.id,
      status: IngestionStatus.fromString(
        d['status'] as String? ?? 'needsReview',
      ),
      source: IngestionSource.fromString(
        d['source'] as String? ?? 'receiptOcr',
      ),
      createdByUserId: d['createdByUserId'] as String? ?? '',
      amountMinor: (d['amountMinor'] as num?)?.toInt(),
      merchant: d['merchant'] as String?,
      bookingDate: d['bookingDate'] as String?,
      accountId: d['accountId'] as String?,
      categoryId: d['categoryId'] as String?,
      createdAt: created is Timestamp ? created.toDate() : null,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }
}

/// Fields the user may edit before confirming a draft.
class IngestionDraftUpdate {
  const IngestionDraftUpdate({
    required this.amountMinor,
    required this.bookingDate,
    required this.accountId,
    required this.categoryId,
    this.merchant,
  });

  final int amountMinor;
  final String bookingDate;
  final String accountId;
  final String categoryId;
  final String? merchant;
}
