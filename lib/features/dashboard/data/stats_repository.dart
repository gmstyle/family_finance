import 'package:cloud_firestore/cloud_firestore.dart';

import '../../budgets/domain/budget.dart';
import '../domain/month_stats.dart';

/// Read-only streams of monthly rollups — never scan transactions.
class StatsRepository {
  StatsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(
    String familyId,
    String periodId,
  ) => _firestore
      .collection('families')
      .doc(familyId)
      .collection('stats')
      .doc(periodId);

  Stream<MonthStats> watchMonthStats(String familyId, String periodId) {
    return _doc(familyId, periodId).snapshots().map((doc) {
      if (!doc.exists) {
        return MonthStats(
          id: periodId,
          totalIncomeMinor: 0,
          totalExpenseMinor: 0,
          incomeByCategory: const {},
          expenseByCategory: const {},
          incomeByAccount: const {},
          expenseByAccount: const {},
        );
      }
      return MonthStats.fromDoc(doc);
    });
  }

  /// Convenience: current local calendar month.
  Stream<MonthStats> watchCurrentMonth(String familyId) =>
      watchMonthStats(familyId, currentBudgetPeriodId());
}
