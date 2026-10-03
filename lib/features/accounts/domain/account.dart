import 'package:cloud_firestore/cloud_firestore.dart';

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
