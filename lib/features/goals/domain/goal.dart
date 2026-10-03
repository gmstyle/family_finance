import 'package:cloud_firestore/cloud_firestore.dart';

/// Goal document. [accumulatedAmountMinor] is function-derived.
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmountMinor,
    required this.accumulatedAmountMinor,
    this.dueDate,
  });

  final String id;
  final String name;
  final int targetAmountMinor;
  final int accumulatedAmountMinor;
  final String? dueDate;

  double get progress {
    if (targetAmountMinor <= 0) return 0;
    return (accumulatedAmountMinor / targetAmountMinor).clamp(0.0, 1.0);
  }

  factory Goal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Goal(
      id: doc.id,
      name: d['name'] as String? ?? '',
      targetAmountMinor: (d['targetAmountMinor'] as num?)?.toInt() ?? 0,
      accumulatedAmountMinor:
          (d['accumulatedAmountMinor'] as num?)?.toInt() ?? 0,
      dueDate: d['dueDate'] as String?,
    );
  }
}

/// Virtual contribution — positive = deposit, negative = withdraw.
class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.amountMinor,
    required this.bookingDate,
    required this.createdByUserId,
  });

  final String id;
  final int amountMinor;
  final String bookingDate;
  final String createdByUserId;

  bool get isDeposit => amountMinor > 0;

  factory GoalContribution.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return GoalContribution(
      id: doc.id,
      amountMinor: (d['amountMinor'] as num?)?.toInt() ?? 0,
      bookingDate: d['bookingDate'] as String? ?? '',
      createdByUserId: d['createdByUserId'] as String? ?? '',
    );
  }
}
