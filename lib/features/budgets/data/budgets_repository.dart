import 'dart:async';

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

/// Firestore CRUD for budgets; periods are read-only for the client.
class BudgetsRepository {
  BudgetsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String familyId) =>
      _firestore.collection('families').doc(familyId).collection('budgets');

  Stream<List<Budget>> watchBudgets(String familyId) {
    return _col(familyId).snapshots().map((snap) {
      final list = snap.docs.map(Budget.fromDoc).toList()
        ..sort((a, b) => a.categoryId.compareTo(b.categoryId));
      return list;
    });
  }

  Stream<BudgetPeriod> watchPeriod(
    String familyId,
    String budgetId,
    String periodId,
  ) {
    return _col(familyId)
        .doc(budgetId)
        .collection('periods')
        .doc(periodId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return BudgetPeriod(
              id: periodId,
              spentAmountMinor: 0,
              threshold80Notified: false,
              threshold100Notified: false,
            );
          }
          return BudgetPeriod.fromDoc(doc);
        });
  }

  /// Live budgets joined with the current period doc (spent + threshold flags).
  Stream<List<BudgetWithPeriod>> watchBudgetsWithPeriod(
    String familyId,
    String periodId,
  ) {
    return watchBudgets(familyId).asyncExpand((budgets) {
      if (budgets.isEmpty) {
        return Stream.value(const <BudgetWithPeriod>[]);
      }
      final periodStreams = budgets
          .map((b) => watchPeriod(familyId, b.id, periodId))
          .toList();
      return _combineLatest(periodStreams).map((periods) {
        return [
          for (var i = 0; i < budgets.length; i++)
            BudgetWithPeriod(budget: budgets[i], period: periods[i]),
        ];
      });
    });
  }

  Future<Budget?> getBudget(String familyId, String budgetId) async {
    final doc = await _col(familyId).doc(budgetId).get();
    if (!doc.exists) return null;
    return Budget.fromDoc(doc);
  }

  Future<String> createBudget({
    required String familyId,
    required String categoryId,
    required int limitAmountMinor,
  }) async {
    final ref = _col(familyId).doc();
    await ref.set({
      'categoryId': categoryId,
      'limitAmountMinor': limitAmountMinor,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateBudget({
    required String familyId,
    required String budgetId,
    required int limitAmountMinor,
  }) {
    return _col(familyId).doc(budgetId).update({
      'limitAmountMinor': limitAmountMinor,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBudget({
    required String familyId,
    required String budgetId,
  }) {
    return _col(familyId).doc(budgetId).delete();
  }
}

/// Emits whenever any source stream emits; values are the latest from each.
Stream<List<T>> _combineLatest<T>(List<Stream<T>> streams) {
  if (streams.isEmpty) return Stream.value(const []);

  final latest = List<T?>.filled(streams.length, null);
  final hasValue = List<bool>.filled(streams.length, false);

  return Stream.multi((controller) {
    final subs = <StreamSubscription<T>>[];

    void emitIfReady() {
      if (hasValue.every((h) => h)) {
        controller.add(List<T>.generate(streams.length, (i) => latest[i] as T));
      }
    }

    for (var i = 0; i < streams.length; i++) {
      final index = i;
      subs.add(
        streams[i].listen((value) {
          latest[index] = value;
          hasValue[index] = true;
          emitIfReady();
        }, onError: controller.addError),
      );
    }

    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };
  });
}
