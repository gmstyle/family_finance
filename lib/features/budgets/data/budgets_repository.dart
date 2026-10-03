import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/budget.dart';

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
  ///
  /// Diff-based: keeps the budgets listener and only adds/cancels period
  /// subscriptions when the set of budget ids changes.
  Stream<List<BudgetWithPeriod>> watchBudgetsWithPeriod(
    String familyId,
    String periodId,
  ) {
    return Stream.multi((controller) {
      final periodByBudgetId = <String, BudgetPeriod>{};
      final periodSubs = <String, StreamSubscription<BudgetPeriod>>{};
      var currentBudgets = <Budget>[];
      var budgetsReady = false;
      StreamSubscription<List<Budget>>? budgetsSub;

      void emit() {
        if (!budgetsReady) return;
        if (currentBudgets.isEmpty) {
          controller.add(const <BudgetWithPeriod>[]);
          return;
        }
        if (!currentBudgets.every((b) => periodByBudgetId.containsKey(b.id))) {
          return;
        }
        controller.add([
          for (final b in currentBudgets)
            BudgetWithPeriod(budget: b, period: periodByBudgetId[b.id]!),
        ]);
      }

      void syncPeriodSubs(List<Budget> budgets) {
        final nextIds = budgets.map((b) => b.id).toSet();
        final prevIds = periodSubs.keys.toSet();

        for (final id in prevIds.difference(nextIds)) {
          unawaited(periodSubs.remove(id)?.cancel() ?? Future<void>.value());
          periodByBudgetId.remove(id);
        }

        for (final budget in budgets) {
          if (periodSubs.containsKey(budget.id)) continue;
          periodSubs[budget.id] = watchPeriod(familyId, budget.id, periodId)
              .listen((period) {
                periodByBudgetId[budget.id] = period;
                emit();
              }, onError: controller.addError);
        }
      }

      budgetsSub = watchBudgets(familyId).listen((budgets) {
        currentBudgets = budgets;
        budgetsReady = true;
        syncPeriodSubs(budgets);
        emit();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await budgetsSub?.cancel();
        for (final sub in periodSubs.values) {
          await sub.cancel();
        }
        periodSubs.clear();
        periodByBudgetId.clear();
      };
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
