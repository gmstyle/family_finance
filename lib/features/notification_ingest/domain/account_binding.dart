import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps a notification source package to a suggested ledger account.
class AccountBinding {
  const AccountBinding({
    required this.id,
    required this.packageName,
    required this.accountId,
  });

  /// Document id (usually the package name).
  final String id;
  final String packageName;
  final String accountId;

  factory AccountBinding.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return AccountBinding(
      id: doc.id,
      packageName: (d['packageName'] as String?)?.trim().isNotEmpty == true
          ? (d['packageName'] as String).trim()
          : doc.id,
      accountId: d['accountId'] as String? ?? '',
    );
  }
}
