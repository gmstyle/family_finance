import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../notification_ingest/data/account_bindings_repository.dart';
import '../../notification_ingest/domain/bank_notification_parser.dart';
import '../../transactions/data/transactions_repository.dart';
import '../domain/italian_receipt_parser.dart';

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

/// Firestore access for `ingestion` drafts + `merchantRules` suggestions.
///
/// OCR / notification never create ledger transactions here — only drafts.
/// [confirmDraft] is the sole path to a real transaction.
class IngestionRepository {
  IngestionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    TransactionsRepository? transactions,
    AccountBindingsRepository? accountBindings,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _transactions = transactions ?? TransactionsRepository(),
       _accountBindings = accountBindings ?? AccountBindingsRepository();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TransactionsRepository _transactions;
  final AccountBindingsRepository _accountBindings;

  CollectionReference<Map<String, dynamic>> _ingestion(String familyId) =>
      _firestore.collection('families').doc(familyId).collection('ingestion');

  CollectionReference<Map<String, dynamic>> _merchantRules(String familyId) =>
      _firestore
          .collection('families')
          .doc(familyId)
          .collection('merchantRules');

  CollectionReference<Map<String, dynamic>> _transactionsCol(String familyId) =>
      _firestore
          .collection('families')
          .doc(familyId)
          .collection('transactions');

  /// Pending drafts oldest-first (needs review / possible duplicate).
  Stream<List<IngestionDraft>> watchPendingQueue(String familyId) {
    return _ingestion(familyId)
        .where(
          'status',
          whereIn: [
            IngestionStatus.needsReview.name,
            IngestionStatus.possibleDuplicate.name,
          ],
        )
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(IngestionDraft.fromDoc).toList()
            ..sort((a, b) {
              final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return aAt.compareTo(bAt);
            });
          return list;
        });
  }

  Future<IngestionDraft?> getDraft(String familyId, String dedupKey) async {
    final doc = await _ingestion(familyId).doc(dedupKey).get();
    if (!doc.exists) return null;
    return IngestionDraft.fromDoc(doc);
  }

  Stream<IngestionDraft?> watchDraft(String familyId, String dedupKey) {
    return _ingestion(familyId).doc(dedupKey).snapshots().map((doc) {
      if (!doc.exists) return null;
      return IngestionDraft.fromDoc(doc);
    });
  }

  Future<MerchantRule?> getMerchantRule(
    String familyId,
    String merchantKey,
  ) async {
    if (merchantKey.isEmpty) return null;
    final doc = await _merchantRules(familyId).doc(merchantKey).get();
    if (!doc.exists) return null;
    return MerchantRule.fromDoc(doc);
  }

  /// Normalizes merchant text into a stable Firestore document id.
  static String merchantKeyFor(String? merchant) {
    final raw = (merchant ?? '').trim().toLowerCase();
    if (raw.isEmpty) return '';
    final collapsed = raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final trimmed = collapsed.replaceAll(RegExp(r'^_+|_+$'), '');
    if (trimmed.isEmpty) return '';
    return trimmed.length > 64 ? trimmed.substring(0, 64) : trimmed;
  }

  /// Creates an Ingestion draft from OCR parse results (never a transaction).
  Future<String> createDraftFromOcr({
    required String familyId,
    required ParsedReceipt parsed,
    String? defaultAccountId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in required to create an ingestion draft.');
    }

    final merchant = parsed.merchant?.trim();
    final merchantKey = merchantKeyFor(merchant);
    final rule = merchantKey.isEmpty
        ? null
        : await getMerchantRule(familyId, merchantKey);

    final accountId = rule?.accountId ?? defaultAccountId;
    final categoryId = rule?.categoryId;
    final bookingDate = parsed.bookingDate;
    final amountMinor = parsed.amountMinor;

    final status = await _detectDuplicateStatus(
      familyId: familyId,
      amountMinor: amountMinor,
      bookingDate: bookingDate,
      merchant: merchant,
    );

    final dedupKey = _buildOcrDedupKey(
      familyId: familyId,
      amountMinor: amountMinor,
      bookingDate: bookingDate,
      merchant: merchant,
      uid: uid,
    );

    await _ingestion(familyId).doc(dedupKey).set({
      'status': status.name,
      'source': IngestionSource.receiptOcr.name,
      'createdByUserId': uid,
      'amountMinor': ?amountMinor,
      if (merchant != null && merchant.isNotEmpty) 'merchant': merchant,
      if (bookingDate != null && bookingDate.isNotEmpty)
        'bookingDate': bookingDate,
      if (accountId != null && accountId.isNotEmpty) 'accountId': accountId,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return dedupKey;
  }

  /// Creates an Ingestion draft from a parsed bank notification.
  ///
  /// Applies [merchantRules] and [accountBindings] as editable suggestions.
  /// Never persists raw notification text. Never creates a ledger transaction.
  /// Dedup key is stable from amount + date + merchant + package.
  Future<NotificationDraftResult> createDraftFromNotification({
    required String familyId,
    required ParsedBankNotification parsed,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in required to create an ingestion draft.');
    }

    final packageName = parsed.packageName.trim();
    final merchant = parsed.merchant?.trim();
    final merchantKey = merchantKeyFor(merchant);
    final rule = merchantKey.isEmpty
        ? null
        : await getMerchantRule(familyId, merchantKey);
    final binding = packageName.isEmpty
        ? null
        : await _accountBindings.getBindingForPackage(familyId, packageName);

    // Merchant rule wins for account; binding is the package-level default.
    final accountId = rule?.accountId ?? binding?.accountId;
    final categoryId = rule?.categoryId;
    final bookingDate = parsed.bookingDate;
    final amountMinor = parsed.amountMinor;

    final dedupKey = _buildNotificationDedupKey(
      amountMinor: amountMinor,
      bookingDate: bookingDate,
      merchant: merchant,
      packageName: packageName,
    );

    final existing = await getDraft(familyId, dedupKey);
    if (existing != null) {
      return NotificationDraftResult(
        dedupKey: dedupKey,
        created: false,
        status: existing.status,
      );
    }

    final status = await _detectDuplicateStatus(
      familyId: familyId,
      amountMinor: amountMinor,
      bookingDate: bookingDate,
      merchant: merchant,
    );

    await _ingestion(familyId).doc(dedupKey).set({
      'status': status.name,
      'source': IngestionSource.notification.name,
      'createdByUserId': uid,
      'amountMinor': ?amountMinor,
      if (merchant != null && merchant.isNotEmpty) 'merchant': merchant,
      if (bookingDate != null && bookingDate.isNotEmpty)
        'bookingDate': bookingDate,
      if (accountId != null && accountId.isNotEmpty) 'accountId': accountId,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (packageName.isNotEmpty) 'sourcePackage': packageName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return NotificationDraftResult(
      dedupKey: dedupKey,
      created: true,
      status: status,
    );
  }

  Future<void> updateDraft({
    required String familyId,
    required String dedupKey,
    required IngestionDraftUpdate update,
  }) async {
    if (update.amountMinor <= 0) {
      throw ArgumentError.value(
        update.amountMinor,
        'amountMinor',
        'must be > 0',
      );
    }
    final merchant = update.merchant?.trim();
    await _ingestion(familyId).doc(dedupKey).update({
      'amountMinor': update.amountMinor,
      'bookingDate': update.bookingDate,
      'accountId': update.accountId,
      'categoryId': update.categoryId,
      'merchant': merchant == null || merchant.isEmpty ? null : merchant,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Confirms a draft: creates a real expense transaction and optional rule.
  ///
  /// Never called automatically from OCR — only from explicit user action.
  Future<String> confirmDraft({
    required String familyId,
    required String dedupKey,
    required IngestionDraftUpdate update,
    required String currency,
    bool saveMerchantRule = true,
  }) async {
    if (update.amountMinor <= 0) {
      throw ArgumentError.value(
        update.amountMinor,
        'amountMinor',
        'must be > 0',
      );
    }

    final draftRef = _ingestion(familyId).doc(dedupKey);
    final snap = await draftRef.get();
    if (!snap.exists) {
      throw StateError('Ingestion draft not found.');
    }
    final draft = IngestionDraft.fromDoc(snap);
    if (!draft.isPending) {
      throw StateError('Draft is not pending review.');
    }

    // Persist edits first so the draft mirrors what was confirmed.
    await updateDraft(familyId: familyId, dedupKey: dedupKey, update: update);

    final txId = await _transactions.createManualTransaction(
      familyId: familyId,
      type: TransactionType.expense,
      accountId: update.accountId,
      categoryId: update.categoryId,
      amountMinor: update.amountMinor,
      currency: currency,
      bookingDate: update.bookingDate,
      merchant: update.merchant,
    );

    if (saveMerchantRule) {
      final key = merchantKeyFor(update.merchant);
      if (key.isNotEmpty) {
        await _merchantRules(familyId).doc(key).set({
          'categoryId': update.categoryId,
          'accountId': update.accountId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    await draftRef.update({
      'status': IngestionStatus.confirmed.name,
      'amountMinor': update.amountMinor,
      'bookingDate': update.bookingDate,
      'accountId': update.accountId,
      'categoryId': update.categoryId,
      'merchant': update.merchant?.trim().isEmpty ?? true
          ? null
          : update.merchant!.trim(),
      'confirmedTransactionId': txId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return txId;
  }

  Future<void> discardDraft({
    required String familyId,
    required String dedupKey,
  }) async {
    final draftRef = _ingestion(familyId).doc(dedupKey);
    final snap = await draftRef.get();
    if (!snap.exists) return;
    final draft = IngestionDraft.fromDoc(snap);
    if (!draft.isPending) {
      throw StateError('Draft is not pending review.');
    }
    await draftRef.update({
      'status': IngestionStatus.discarded.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<IngestionStatus> _detectDuplicateStatus({
    required String familyId,
    required int? amountMinor,
    required String? bookingDate,
    required String? merchant,
  }) async {
    if (amountMinor == null ||
        bookingDate == null ||
        bookingDate.isEmpty ||
        merchant == null ||
        merchant.trim().isEmpty) {
      return IngestionStatus.needsReview;
    }

    final snap = await _transactionsCol(familyId)
        .where('bookingDate', isEqualTo: bookingDate)
        .where('amountMinor', isEqualTo: amountMinor)
        .limit(10)
        .get();

    final needle = merchant.trim().toLowerCase();
    for (final doc in snap.docs) {
      final m = (doc.data()['merchant'] as String?)?.trim().toLowerCase();
      if (m != null && m.isNotEmpty && m == needle) {
        return IngestionStatus.possibleDuplicate;
      }
    }
    return IngestionStatus.needsReview;
  }

  String _buildOcrDedupKey({
    required String familyId,
    required int? amountMinor,
    required String? bookingDate,
    required String? merchant,
    required String uid,
  }) {
    final material =
        'ocr|$familyId|${amountMinor ?? ''}|${bookingDate ?? ''}|'
        '${(merchant ?? '').trim().toLowerCase()}|$uid|'
        '${DateTime.now().microsecondsSinceEpoch}';
    final digest = sha256.convert(utf8.encode(material)).toString();
    return 'ocr_${digest.substring(0, 32)}';
  }

  /// Stable dedup key from amount + date + merchant + package (no raw text).
  String _buildNotificationDedupKey({
    required int? amountMinor,
    required String? bookingDate,
    required String? merchant,
    required String packageName,
  }) {
    final material =
        'notif|${amountMinor ?? ''}|${bookingDate ?? ''}|'
        '${(merchant ?? '').trim().toLowerCase()}|'
        '${packageName.trim().toLowerCase()}';
    final digest = sha256.convert(utf8.encode(material)).toString();
    return 'notif_${digest.substring(0, 32)}';
  }
}
