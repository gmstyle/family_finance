import 'package:cloud_firestore/cloud_firestore.dart';

import '../../budgets/data/budgets_repository.dart';

/// Monthly stats rollup at `families/{id}/stats/{yyyy-MM}` (function-only writes).
class MonthStats {
  const MonthStats({
    required this.id,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.incomeByAccount,
    required this.expenseByAccount,
  });

  final String id;
  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final Map<String, int> incomeByCategory;
  final Map<String, int> expenseByCategory;
  final Map<String, int> incomeByAccount;
  final Map<String, int> expenseByAccount;

  int get netMinor => totalIncomeMinor - totalExpenseMinor;

  static const empty = MonthStats(
    id: '',
    totalIncomeMinor: 0,
    totalExpenseMinor: 0,
    incomeByCategory: {},
    expenseByCategory: {},
    incomeByAccount: {},
    expenseByAccount: {},
  );

  factory MonthStats.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return MonthStats(
      id: doc.id,
      totalIncomeMinor: (d['totalIncomeMinor'] as num?)?.toInt() ?? 0,
      totalExpenseMinor: (d['totalExpenseMinor'] as num?)?.toInt() ?? 0,
      incomeByCategory: _intMap(d['incomeByCategory']),
      expenseByCategory: _intMap(d['expenseByCategory']),
      incomeByAccount: _intMap(d['incomeByAccount']),
      expenseByAccount: _intMap(d['expenseByAccount']),
    );
  }

  static Map<String, int> _intMap(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        e.key.toString(): (e.value as num?)?.toInt() ?? 0,
    };
  }
}

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
