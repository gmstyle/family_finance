import 'package:cloud_firestore/cloud_firestore.dart';

/// Budget document: monthly limit for one expense category.
class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.limitAmountMinor,
  });

  final String id;
  final String categoryId;
  final int limitAmountMinor;

  factory Budget.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Budget(
      id: doc.id,
      categoryId: d['categoryId'] as String? ?? '',
      limitAmountMinor: (d['limitAmountMinor'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Function-owned period rollup under `budgets/{id}/periods/{yyyy-MM}`.
class BudgetPeriod {
  const BudgetPeriod({
    required this.id,
    required this.spentAmountMinor,
    required this.threshold80Notified,
    required this.threshold100Notified,
  });

  final String id;
  final int spentAmountMinor;
  final bool threshold80Notified;
  final bool threshold100Notified;

  factory BudgetPeriod.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return BudgetPeriod(
      id: doc.id,
      spentAmountMinor: (d['spentAmountMinor'] as num?)?.toInt() ?? 0,
      threshold80Notified: d['threshold80Notified'] as bool? ?? false,
      threshold100Notified: d['threshold100Notified'] as bool? ?? false,
    );
  }

  /// Visual threshold from spent vs limit (independent of FCM flags).
  BudgetThresholdState thresholdState(int limitAmountMinor) {
    if (limitAmountMinor <= 0) return BudgetThresholdState.ok;
    if (spentAmountMinor >= limitAmountMinor) {
      return BudgetThresholdState.atOrOver100;
    }
    if (spentAmountMinor >= (limitAmountMinor * 0.8).floor()) {
      return BudgetThresholdState.atOrOver80;
    }
    return BudgetThresholdState.ok;
  }
}

enum BudgetThresholdState { ok, atOrOver80, atOrOver100 }

class BudgetWithPeriod {
  const BudgetWithPeriod({required this.budget, required this.period});

  final Budget budget;
  final BudgetPeriod period;
}

/// Current calendar period id `yyyy-MM` (booking-date period, local clock).
String currentBudgetPeriodId([DateTime? now]) {
  final d = now ?? DateTime.now();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  return '$y-$m';
}
